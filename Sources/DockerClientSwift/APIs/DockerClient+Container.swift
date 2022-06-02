import Foundation
import NIO

extension DockerClient {
    
    /// APIs related to containers.
    public var containers: ContainersAPI {
        .init(client: self)
    }
    
    public struct ContainersAPI {
        fileprivate var client: DockerClient
        
        /// Fetches all containers in the Docker system.
        /// - Parameter all: If `true` all containers are fetched, otherwise only running containers.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns a list of `Container`.
        public func list(all: Bool=false) async throws -> [Container] {
            try await client.run(ListContainersEndpoint(all: all))
                .map({ container in
                    var digest: Digest?
                    var repositoryTag: Image.RepositoryTag?
                    if let value =  Image.parseNameTagDigest(container.Image) {
                        (digest, repositoryTag) = value
                    } else if let repoTag = Image.RepositoryTag(container.Image) {
                        repositoryTag = repoTag
                    }
                    let image = Image(id: .init(container.ImageID), digest: digest, repositoryTags: repositoryTag.map({ [$0]}), createdAt: nil)
                    return Container(id: .init(container.Id), image: image, createdAt: Date(timeIntervalSince1970: TimeInterval(container.Created)), names: container.Names, state: container.State, command: container.Command)
                })
        }
        
        /// Creates a new container from a given image. If specified the commands override the default commands from the image.
        /// - Parameters:
        ///   - image: Instance of an `Image`.
        ///   - commands: Override the default commands from the image. Default `nil`.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns  a `Container`.
        public func createContainer(image: Image, commands: [String]?=nil) async throws -> Container {
            let response = try await client.run(CreateContainerEndpoint(imageName: image.id.value, commands: commands))
            return try await self.get(containerByNameOrId: response.Id)
        }
        
        /// Starts a container. Before starting it needs to be created.
        /// - Parameter container: Instance of a created `Container`.
        /// - Throws: Errors that can occur when executing the request.
        public func start(container: Container) async throws {
            try await client.run(StartContainerEndpoint(containerId: container.id.value))
        }
        
        /// Stops a container. Before stopping it needs to be created and started..
        /// - Parameter container: Instance of a started `Container`.
        /// - Throws: Errors that can occur when executing the request.
        public func stop(container: Container) async throws {
            try await client.run(StopContainerEndpoint(containerId: container.id.value))
        }
        
        /// Removes an existing container.
        /// - Parameter container: Instance of an existing `Container`.
        /// - Throws: Errors that can occur when executing the request.
        public func remove(container: Container) async throws {
            try await client.run(RemoveContainerEndpoint(containerId: container.id.value))
        }
        
        /// Gets the logs of a container as plain text. This function does not return future log statements but only the once that happen until now.
        /// - Parameter container: Instance of a `Container` you want to get the logs for.
        /// - Throws: Errors that can occur when executing the request.
        public func logs(container: Container) async throws -> String {
            let response = try await client.run(GetContainerLogsEndpoint(containerId: container.id.value))
            // Removing the first character of each line because random characters went there.
            // TODO: first char is the stream (stdout/stderr). Return structured messages instead of a string
            return response.split(separator: "\n")
                .map({ originalLine in
                    var line = originalLine
                    line.removeFirst(8)
                    return String(line)
                })
                .joined(separator: "\n")
        }
        
        /// Fetches the latest information about a container by a given name or id..
        /// - Parameter nameOrId: Name or id of a container.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns the `Container` and its information.
        public func get(containerByNameOrId nameOrId: String) async throws -> Container {
            let response = try await client.run(InspectContainerEndpoint(nameOrId: nameOrId))
            var digest: Digest?
            var repositoryTag: Image.RepositoryTag?
            if let value =  Image.parseNameTagDigest(response.Image) {
                (digest, repositoryTag) = value
            } else if let repoTag = Image.RepositoryTag(response.Image) {
                repositoryTag = repoTag
            }
            let image = Image(id: .init(response.Image), digest: digest, repositoryTags: repositoryTag.map({ [$0]}), createdAt: nil)
            return Container(
                id: .init(response.Id),
                image: image,
                createdAt: Date.parseDockerDate(response.Created)!,
                names: [response.Name],
                state: response.State.Status,
                command: response.Config.Cmd.joined(separator: " ")
            )
        }
        
        
        /// Deletes all stopped containers.
        /// - Throws: Errors that can occur when executing the request.
        /// - Returns: Returns an `EventLoopFuture` with a list of deleted `Container` and the reclaimed space.
        public func prune() async throws -> PrunedContainers {
            let response =  try await client.run(PruneContainersEndpoint())
            return PrunedContainers(
                containersIds: response.ContainersDeleted?.map({ .init($0)}) ?? [],
                reclaimedSpace: response.SpaceReclaimed
            )
        }
        
        public struct PrunedContainers {
            let containersIds: [Identifier<Container>]
            
            /// Disk space reclaimed in bytes
            let reclaimedSpace: Int
        }
    }
}

extension Container {
    /// Starts a container.
    /// - Parameter client: A `DockerClient` instance that is used to perform the request.
    /// - Throws: Errors that can occur when executing the request.
    /// - Returns: Returns an `EventLoopFuture` when the container is started.
    public func start(on client: DockerClient) async throws {
        try await client.containers.start(container: self)
    }
    
    /// Stops a container.
    /// - Parameter client: A `DockerClient` instance that is used to perform the request.
    /// - Throws: Errors that can occur when executing the request.
    /// - Returns: Returns an `EventLoopFuture` when the container is stopped.
    public func stop(on client: DockerClient) async throws {
        try await client.containers.stop(container: self)
    }
    
    /// Removes a container
    /// - Parameter client: A `DockerClient` instance that is used to perform the request.
    /// - Throws: Errors that can occur when executing the request.
    /// - Returns: Returns an `EventLoopFuture` when the container is removed.
    public func remove(on client: DockerClient) async throws {
        try await client.containers.remove(container: self)
    }
    
    /// Gets the logs of a container as plain text. This function does not return future log statements but only the once that happen until now.
    /// - Parameter client: A `DockerClient` instance that is used to perform the request.
    /// - Throws: Errors that can occur when executing the request.
    /// - Returns: Return an `EventLoopFuture` with the logs as a plain text `String`.
    public func logs(on client: DockerClient) async throws -> String {
        return try await client.containers.logs(container: self)
    }
}
