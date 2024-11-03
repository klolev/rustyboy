// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenVGDB",
    products: [
        .library(name: "OpenVGDB", targets: ["OpenVGDB"]),
    ],
    dependencies: [.package(url: "https://github.com/stephencelis/SQLite.swift", from: "0.15.3")],
    targets: [
        .target(name: "OpenVGDB",
                dependencies: [.product(name: "SQLite", package: "SQLite.swift")],
                resources: [.copy("Resources/openvgdb.sqlite")])
    ]
)
