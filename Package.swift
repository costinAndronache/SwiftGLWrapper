// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swiftGLRendering",
    dependencies: [
        .package(path: "./swiftGLFW"),
        .package(path: "./swiftSTBImage"),
        .package(url: "https://github.com/costinAndronache/SGLOpenGL.git", exact: "3.1.0"),
        .package(url: "https://github.com/recp/cglm.git", exact: "0.9.6")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "swiftGLRendering",
            dependencies: [
                .product(name: "swiftGLFW", package: "swiftGLFW"),
                .product(name: "SGLOpenGL", package: "SGLOpenGL"),
                .product(name: "cglm", package: "cglm"),
                .product(name: "swiftSTBImage", package: "swiftSTBImage")
            ],
            swiftSettings: [
                .interoperabilityMode(.C)
            ],
            linkerSettings: [
                .unsafeFlags(["-L./swiftGLFW/Sources/swiftGLFW/glfw-3.4.bin.WIN64/lib-vc2022"])
            ])
    ]
)
