import XCTest
@testable import DockerSwift
import Logging

final class ContainerTests: XCTestCase {
    
    var client: DockerClient!
    
    override func setUp() async throws {
        client = DockerClient.testable()
        if (try? await client.images.get("nginx:latest")) == nil {
            _ = try await client.images.pull(byName: "nginx", tag: "latest")
        }
        if (try? await client.images.get("hello-world:latest")) == nil {
            _ = try await client.images.pull(byName: "hello-world", tag: "latest")
        }
    }
    
    override func tearDownWithError() throws {
        try client.syncShutdown()
    }
    
    
    func testAttach() async throws {
        let _ = try await client.images.pull(byName: "alpine", tag: "latest")
        let spec = ContainerSpec(
            config: .init(
                image: "alpine:latest",
                attachStdin: true,
                attachStdout: true,
                attachStderr: true,
                openStdin: true
            )
        )
        let container = try await client.containers.create(spec: spec)
        let attach = try await client.containers.attach(container: container, stream: true, logs: true)
        do {
            Task {
                for try await output in attach.output {
                    XCTAssert(output == "Linux\n", "Ensure command output is properly read")
                }
            }
            try await client.containers.start(container.id)
            
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await attach.send("uname")
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        catch(let error) {
            print("\n••••• BOOM! \(error)")
            throw error
        }
        
        try await client.containers.remove(container.id, force: true)
    }
    
    func testCreateContainer() async throws {
        let cmd = ["/custom/command", "--option"]
        let spec = ContainerSpec(
            config: .init(
                image: "hello-world:latest",
                // Override the default command of the Image
                command: cmd,
                // Add new environment variables
                environmentVars: ["HELLO=hi"],
                // Expose port 80
                exposedPorts: [.tcp(80)],
                // Set custon container labels
                labels: ["label1": "value1", "label2": "value2"]
            ),
            hostConfig: .init(
                // Memory the container is allocated when starting
                memoryReservation: .mb(32),
                // Maximum memory the container can use
                memoryLimit: .mb(64),
                // Needs to be either disabled (-1) or be equal to, or greater than, `memoryLimit`
                memorySwap: .mb(64),
                // Let's publish the port we exposed in `config`
                portBindings: [.tcp(80): [.publishTo(hostIp: "0.0.0.0", hostPort: 8008)]]
            )
        )
        
        let name = UUID.init().uuidString
        let container = try await client.containers.create(name: name, spec: spec)
        XCTAssert(container.name == "/\(name)", "Ensure name is set")
        XCTAssert(container.config.command == cmd, "Ensure custom command is set")
        XCTAssert(
            container.config.exposedPorts != nil && container.config.exposedPorts![0].port == 80,
            "Ensure Exposed Port was set and retrieved"
        )
        
        XCTAssert(
            container.hostConfig.portBindings != nil && container.hostConfig.portBindings![.tcp(80)] != nil,
            "Ensure Published Port was set and retrieved"
        )
        XCTAssert(container.hostConfig.memoryLimit == .mb(64), "Ensure MemoryLimit is set")
        
        try await client.containers.remove(container.id)
    }
    
    func testUpdateContainers() async throws {
        let name = UUID.init().uuidString
        let spec = ContainerSpec(
            config: ContainerConfig(image: "hello-world:latest"),
            hostConfig: ContainerHostConfig()
        )
        let container = try await client.containers.create(name: name, spec: spec)
        try await client.containers.start(container.id)
        
        let newConfig = ContainerUpdate(memoryLimit: 64 * 1024 * 1024, memorySwap: 64 * 1024 * 1024)
        try await client.containers.update(container.id, spec: newConfig)
        
        let updated = try await client.containers.get(container.id)
        XCTAssert(updated.hostConfig.memoryLimit == 64 * 1024 * 1024, "Ensure param has been updated")
        
        try await client.containers.remove(container.id)
    }
    
    func testListContainers() async throws {
        let container = try await client.containers.create(
            spec: .init(config: .init(image: "hello-world:latest"))
        )
        
        let containers = try await client.containers.list(all: true)
        XCTAssert(containers.count >= 1)
        XCTAssert(containers.first!.createdAt > Date.distantPast)
            
        try await client.containers.remove(container.id)
    }
    
    func testInspectContainer() async throws {
        let container = try await client.containers.create(
            spec: .init(config: .init(image: "hello-world:latest"))
        )
        let inspectedContainer = try await client.containers.get(container.id)
        
        XCTAssertEqual(inspectedContainer.id, container.id)
        XCTAssertEqual(inspectedContainer.config.command, ["/hello"])
    }
    
    func testRetrievingLogsNoTty() async throws {
        let container = try await client.containers.create(
            name: nil,
            spec: ContainerSpec(
                config: ContainerConfig(image: "hello-world:latest", tty: false),
                hostConfig: .init())
        )
        try await client.containers.start(container.id)
        try await Task.sleep(nanoseconds: 3_000_000_000)
        
        var output = ""
        do {
            for try await line in try await client.containers.logs(container: container, timestamps: true) {
                XCTAssert(line.timestamp != Date.distantPast, "Ensure timestamp is parsed properly")
                XCTAssert(line.source == .stdout, "Ensure stdout is properly detected")
                output += line.message + "\n"
                //print("\n>>> LOG: \(line)")
            }
        }
        catch(let error){
            print("\n •••••• BOOM!! \(error)")
            throw error
        }
        // arm64v8 or amd64
        XCTAssertEqual(
            output,
        """

        Hello from Docker!
        This message shows that your installation appears to be working correctly.
        
        To generate this message, Docker took the following steps:
         1. The Docker client contacted the Docker daemon.
         2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
            (arm64v8)
         3. The Docker daemon created a new container from that image which runs the
            executable that produces the output you are currently reading.
         4. The Docker daemon streamed that output to the Docker client, which sent it
            to your terminal.
        
        To try something more ambitious, you can run an Ubuntu container with:
         $ docker run -it ubuntu bash
        
        Share images, automate workflows, and more with a free Docker ID:
         https://hub.docker.com/
        
        For more examples and ideas, visit:
         https://docs.docker.com/get-started/
        
        
        """
        )
        
        try await client.containers.remove(container.id)
    }
    
    // Log entries parsing is quite different depending on whether the container has a TTY
    func testRetrievingLogsTty() async throws {
        let container = try await client.containers.create(
            name: nil,
            spec: ContainerSpec(
                config: ContainerConfig(image: "hello-world:latest", tty: true),
                hostConfig: .init())
        )
        try await client.containers.start(container.id)
        
        var output = ""
        for try await line in try await client.containers.logs(container: container, timestamps: true) {
            XCTAssert(line.timestamp != Date.distantPast, "Ensure timestamp is parsed properly")
            XCTAssert(line.source == .stdout, "Ensure stdout is properly detected")
            output += line.message + "\n"
        }
        // arm64v8 or amd64
        XCTAssertEqual(
            output,
        """
        
        Hello from Docker!
        This message shows that your installation appears to be working correctly.
        
        To generate this message, Docker took the following steps:
         1. The Docker client contacted the Docker daemon.
         2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
            (arm64v8)
         3. The Docker daemon created a new container from that image which runs the
            executable that produces the output you are currently reading.
         4. The Docker daemon streamed that output to the Docker client, which sent it
            to your terminal.
        
        To try something more ambitious, you can run an Ubuntu container with:
         $ docker run -it ubuntu bash
        
        Share images, automate workflows, and more with a free Docker ID:
         https://hub.docker.com/
        
        For more examples and ideas, visit:
         https://docs.docker.com/get-started/
        
        
        """
        )
    }
    
    func testPruneContainers() async throws {
        let container = try await client.containers.create(
            spec: .init(config: .init(image: "nginx:latest"))
        )
        
        try await client.containers.start(container.id)
        try await client.containers.stop(container.id)
        
        let pruned = try await client.containers.prune()
        let containers = try await client.containers.list(all: true)
        XCTAssert(!containers.map(\.id).contains(container.id))
        XCTAssert(pruned.reclaimedSpace > 0)
        XCTAssert(pruned.containersIds.contains(container.id))
    }
    
    func testPauseUnpauseContainers() async throws {
        let image = try await client.images.pull(byName: "nginx", tag: "latest")
        let container = try await client.containers.create(image: image)
        try await client.containers.start(container.id)
        
        try await client.containers.pause(container.id)
        let paused = try await client.containers.get(container.id)
        XCTAssert(paused.state.paused, "Ensure container is paused")
        
        try await client.containers.unpause(container.id)
        let unpaused = try await client.containers.get(container.id)
        XCTAssert(unpaused.state.paused == false, "Ensure container is unpaused")
        
        try? await client.containers.remove(container.id, force: true)
    }
    
    func testRenameContainer() async throws {
        let container = try await client.containers.create(
            spec: .init(config: .init(image: "nginx:latest"))
        )
        try await client.containers.start(container.id)
        try await client.containers.rename(container.id, to: "renamed")
        let renamed = try await client.containers.get(container.id)
        XCTAssert(renamed.name == "/renamed", "Ensure container has new name")
        
        try? await client.containers.remove(container.id, force: true)
    }
    
    func testProcessesContainer() async throws {
        let container = try await client.containers.create(
            spec: .init(config: .init(image: "nginx:latest"))
        )
        try await client.containers.start(container.id)
        
        let psInfo = try await client.containers.processes(container.id)
        XCTAssert(psInfo.processes.count > 0, "Ensure processes are parsed")
        
        try? await client.containers.remove(container.id, force: true)
    }
    
    func testStatsContainer() async throws {
        let container = try await client.containers.create(
            spec: .init(config: .init(image: "nginx:latest"))
        )
        try await client.containers.start(container.id)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        do {
            for try await stats in try await client.containers.stats(container.id, stream: false, oneShot: true) {
                XCTAssert(stats.pids.current > 0, "Ensure stats response can be parsed")
            }
        }
        catch(let error) {
            print("\n••• BOOM! \(error)")
            throw error
        }
        try await client.containers.remove(container.id, force: true)
    }
    
    func testWaitContainer() async throws {
        let container = try await client.containers.create(
            spec: .init(config: .init(image: "hello-world:latest"))
        )
        
        try await client.containers.start(container.id)
        let statusCode = try await client.containers.wait(container.id)
        XCTAssert(statusCode == 0, "Ensure container exited properly")
    }
}
