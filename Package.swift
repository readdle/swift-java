// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Java",
    products:[
        .library(
            name: "Java", 
            targets:["Java"]
        )
    ],
    dependencies: [
        // TODO: remove coder and java_swift dependencies
        .package(url: "https://github.com/andriydruk/swift-java-coder.git", .exact("1.0.2")),
        .package(url: "https://github.com/andriydruk/java_swift.git", .exact("2.1.2")),
    ],
    targets: [
        .target(
            name: "Java",
            dependencies: ["JavaCoder", "java_swift"],
            path: "Sources"
        ),
    ],
    swiftLanguageVersions: [4]
)