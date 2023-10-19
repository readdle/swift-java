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
        .package(url: "https://github.com/readdle/swift-java-coder.git", .upToNextMinor(from: "1.1.0")),
        .package(url: "https://github.com/readdle/java_swift.git", .upToNextMinor(from: "2.2.0")),
    ],
    targets: [
        .target(
            name: "Java",
            dependencies: ["JavaCoder", "java_swift"],
            path: "Sources"
        ),
    ],
    swiftLanguageVersions: [5, 4]
)
