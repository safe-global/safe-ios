// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SecureConfig",
    platforms: [.macOS(.v13), .iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SecureConfig",
            targets: ["SecureConfig"]),
        .executable(name: "secconfig", targets: ["secconfig"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SecureConfig"),
        .testTarget(
            name: "SecureConfigTests",
            dependencies: ["SecureConfig"]),
        .executableTarget(name: "secconfig", dependencies: ["SecureConfig"]),
    ]
)
