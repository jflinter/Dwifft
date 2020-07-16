// swift-tools-version:5.2
//

import PackageDescription

let package = Package(
    name: "Dwifft",
    platforms: [
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
