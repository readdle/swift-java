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
        .package(url: "https://github.com/andriydruk/java_swift.git", .exact("2.1.2")),
    ],
    targets: [
        .target(
            name: "Java",
            dependencies: ["java_swift"],
            path: "Sources"
        ),
    ],
    swiftLanguageVersions: [4]
)
