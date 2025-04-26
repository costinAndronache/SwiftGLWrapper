// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftGLRendering",
    dependencies: [
        .package(path: "./swiftGLFW"),
        .package(path: "../SwiftGLOpenGL")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "swiftGLRendering",
            dependencies: [
                .product(name: "swiftGLFW", package: "swiftGLFW"),
                .product(name: "SGLOpenGL", package: "SwiftGLOpenGL")
            ],
            linkerSettings: [
                .unsafeFlags(["-L./swiftGLFW/Sources/swiftGLFW/glfw-3.4.bin.WIN64/lib-vc2022"])
            ])
    ]
)
