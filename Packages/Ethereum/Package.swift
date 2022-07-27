// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ethereum",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Ethereum",
            targets: ["Json", "JsonRpc2", "Ethereum", "Solidity", "SafeAbi", "SafeDeployments", "Eth"]),

        .executable(name: "potato", targets: ["potato", "SafeDeployments"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/attaswift/BigInt.git", .exact("5.3.0")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .exact("1.5.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "Json"),
        .testTarget(name: "JsonTests", dependencies: ["Json", "TestHelpers"]),

        .target(name: "JsonRpc2", dependencies: ["Json"]),
        .testTarget(name: "JsonRpc2Tests", dependencies: ["JsonRpc2", "TestHelpers"]),

        .target(name: "Ethereum", dependencies: ["Json", "JsonRpc2", "Solidity"]),
        .testTarget(name: "EthereumTests", dependencies: ["Ethereum", "TestHelpers"]),

        .target(name: "Solidity", dependencies: ["WordInteger", "CryptoSwift"]),
        .testTarget(name: "SolidityTests", dependencies: ["Solidity"]),

        .target(name: "WordInteger", dependencies: ["BigInt"]),
        .testTarget(name: "WordIntegerTests", dependencies: ["WordInteger"]),

        .target(name: "SafeDeployments", dependencies: ["Solidity"], resources: [.copy("assets")]),
        .testTarget(name: "SafeDeploymentsTests", dependencies: ["SafeDeployments"]),

        .target(name: "TestHelpers"),

        .executableTarget(name: "potato", dependencies: ["SafeDeployments"]),

        .target(name: "SafeAbi", dependencies: ["Solidity"]),

        .target(name: "Eth", dependencies: ["Json", "JsonRpc2", "Solidity"]),
        .testTarget(name: "EthTests", dependencies: ["Eth"])
    ]
)
