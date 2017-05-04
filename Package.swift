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
