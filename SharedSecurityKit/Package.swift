// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SharedSecurityKit",
    platforms: [
        .iOS(
            .v17
        ) // Ensure we have the latest iOS features available
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SharedSecurityKit",
            targets: ["SharedSecurityKit"]
        ),
    ],
    dependencies: [
        // A lightweight CBOR serialization package
        .package(
            url: "https://github.com/myfreeweb/SwiftCBOR.git",
            from: "0.6.0"
        ),
        // A robust JWT package for token generation and verification
        .package(
            url: "https://github.com/Kitura/Swift-JWT.git",
            from: "4.0.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SharedSecurityKit",
            dependencies: [
                "SwiftCBOR",
                .product(
                    name: "SwiftJWT",
                    package: "Swift-JWT"
                )
            ]
        ),
//        .testTarget(
//            name: "SharedSecurityKitTests",
//            dependencies: ["SharedSecurityKit"]
//        ),

    ]
)
