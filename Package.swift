// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FloatingTodoWidget",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "FloatingTodoWidget",
            targets: ["FloatingTodoWidget"]
        )
    ],
    targets: [
        .executableTarget(
            name: "FloatingTodoWidget"
        )
    ]
)
