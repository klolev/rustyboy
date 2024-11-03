// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GameGirlCore",
    platforms: [.iOS(.v14), .macOS(.v10_15)],
    products: [
        .library(
            name: "GameGirlCore",
            targets: ["GameGirlCore", "GameGirlCoreBindings"]),
    ],
    targets: [
        .target(name: "GameGirlCoreBindings", dependencies: ["GameGirlCore"]),
        .binaryTarget(name: "GameGirlCore", 
                      path: "../../../core/target/GameGirlCore.xcframework")
    ]
)
