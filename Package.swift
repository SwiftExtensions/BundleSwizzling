// swift-tools-version: 5.6

import PackageDescription

let package = Package(
    name: "BundleSwizzling",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "BundleSwizzling",
            targets: ["BundleSwizzling"]),
    ],
    targets: [
        .target(name: "BundleSwizzling"),
        .testTarget(
            name: "BundleSwizzlingTests",
            dependencies: ["BundleSwizzling"]),
    ]
)
