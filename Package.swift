// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "EyeCare2020Core",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "EyeCare2020Core", targets: ["EyeCare2020Core"])
    ],
    targets: [
        .target(
            name: "EyeCare2020Core",
            path: "EyeCare2020",
            exclude: [
                "Assets.xcassets",
                "ContentView.swift",
                "EyeCare2020App.swift",
                "Info.plist",
                "Resources",
                "Services",
                "Theme",
                "ViewModels"
            ],
            sources: [
                "Models/NotificationSchedule.swift",
                "Timer/TimerCore.swift"
            ]
        ),
        .testTarget(
            name: "EyeCare2020Tests",
            dependencies: ["EyeCare2020Core"],
            path: "EyeCare2020Tests"
        )
    ]
)
