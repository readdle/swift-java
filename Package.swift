// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Java",
    products: [
        .library(
            name: "Java", 
            targets:["Java"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/SwiftJava/CJavaVM.git", .exact("1.1.3")),
        .package(url: "https://github.com/andriydruk/swift-anycodable.git", .upToNextMinor(from: "1.0.0")),
    ],
    targets: [
        .target(
            name: "Java",
            dependencies: ["AnyCodable"],
            path: "Sources"
        ),
    ],
    swiftLanguageVersions: [5, 4]
)
