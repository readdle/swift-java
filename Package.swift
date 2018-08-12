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
        .package(url: "https://github.com/SwiftJava/CJavaVM.git", .exact("1.1.3")),
    ],
    targets: [
        .target(
            name: "Java",
            /* dependencies: ["CJavaVM"], */
            path: "Sources"
        ),
    ],
    swiftLanguageVersions: [4]
)
