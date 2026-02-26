// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftAndroidApp",
    platforms: [
      .macOS(.v15),
    ],
    products: [
        .library(
            name: "SwiftAndroidApp",
            type: .dynamic,
            targets: ["SwiftAndroidApp"]
        ),
    ],
    dependencies: [
        .package(
            path: "../"
        ),
        .package(
            url: "https://github.com/PureSwift/Android.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "SwiftAndroidApp",
            dependencies: [
                .product(
                    name: "AndroidBluetooth",
                    package: "AndroidBluetooth"
                ),
                .product(
                    name: "AndroidKit",
                    package: "Android"
                )
            ],
            path: "./app/src/main/swift",
            swiftSettings: [
              .swiftLanguageMode(.v5)
            ]
        )
    ]
)
