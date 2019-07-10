// swift-tools-version:5.1
//

import PackageDescription

let package = Package(
    name: "Dwifft",
    platforms: [
        .iOS(.v8),
        .tvOS(.v9),
        .macOS(.v10_11)
    ],
    products: [
        .library(name: "Dwifft", targets: ["Dwifft"])
    ],
    targets: [
        .target(name: "Dwifft", path: "Dwifft")
    ],
    swiftLanguageVersions: [.v5]
)
