// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-bases",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "Base2", targets: ["Base2"]),
        .library(name: "Base8", targets: ["Base8"]),
        .library(name: "BaseX", targets: ["BaseX"]),
        .library(name: "Base32", targets: ["Base32"]),
        .library(name: "Base64", targets: ["Base64"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(name: "Base2", dependencies: []),
        .target(name: "Base8", dependencies: []),
        .target(name: "BaseX", dependencies: []),
        .target(name: "Base32", dependencies: []),
        .target(name: "Base64", dependencies: []),

        .testTarget(
            name: "Base2Tests",
            dependencies: ["Base2"]
        ),
        .testTarget(
            name: "Base8Tests",
            dependencies: ["Base8"]
        ),
        .testTarget(
            name: "Base32Tests",
            dependencies: ["Base32"]
        ),
        .testTarget(
            name: "BaseXTests",
            dependencies: ["BaseX"]
        ),

    ]
)
