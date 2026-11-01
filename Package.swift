// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WMSwitcher",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "WMSwitcher", path: "Sources/WMSwitcher")
    ]
)
