// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "DockerSwift",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "DockerSwift", targets: ["DockerSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.18.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.10.0"),
        // Container attach endpoint
        .package(url: "https://github.com/m-barthelemy/websocket-kit.git", .branch("main")),
        // Only used for parsing the multiple and inconsistent date formats returned by Docker
        .package(url: "https://github.com/marksands/BetterCodable.git", from: "0.4.0")
        // Some Docker features receive or return TAR archives. Used by tests
        //.package(url: "https://github.com/kayembi/Tarscape.git", .branch("main")),
    ],
    targets: [
        .target(
            name: "DockerSwift",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "WebSocketKit", package: "websocket-kit"),
                "BetterCodable",
            ]),
        .testTarget(
            name: "DockerSwiftTests",
            dependencies: [
                "DockerSwift",
                //"Tarscape"
            ]
        ),
    ]
)
