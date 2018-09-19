// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "Dwifft",
    dependencies : [],
    exclude: [
        "Carthage",
        "DwifftTests",
        "DwifftExample",
        "docs",
        "Dwifft.xcworkspace",
        "scripts",
    ]
)
