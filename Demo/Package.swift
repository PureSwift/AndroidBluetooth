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
            targets: ["BluetoothDemoBridge"]
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
        .package(
            url: "https://github.com/swiftlang/swift-java.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-android-sdk/swift-android-native.git",
            from: "2.1.0"
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            from: "4.0.0"
        ),
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            from: "8.0.0"
        )
    ],
    targets: [
        .target(
            name: "BluetoothDemoBridge",
            dependencies: [
                .product(
                    name: "AndroidBluetooth",
                    package: "AndroidBluetooth"
                ),
                .product(
                    name: "AndroidBluetoothBridge",
                    package: "AndroidBluetooth"
                ),
                .product(
                    name: "GATT",
                    package: "GATT"
                ),
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "SwiftJava",
                    package: "swift-java"
                ),
                .product(
                    name: "AndroidKit",
                    package: "Android"
                ),
                .product(
                    name: "AndroidContext",
                    package: "swift-android-native"
                )
            ],
            path: "./app/src/main/swift-bridge/BluetoothDemoBridge",
            exclude: [
              "swift-java.config"
            ],
            swiftSettings: [
              .swiftLanguageMode(.v5)
            ],
            plugins: [
              .plugin(
                name: "JExtractSwiftPlugin",
                package: "swift-java"
              )
            ]
        )
    ]
)
