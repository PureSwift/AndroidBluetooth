// swift-tools-version:6.3
import PackageDescription
import CompilerPluginSupport

import class Foundation.FileManager
import class Foundation.ProcessInfo

// Get NDK version from command line
let environment = ProcessInfo.processInfo.environment
let ndkVersion = environment["ANDROID_NDK_VERSION"].flatMap { UInt($0) } ?? 27
let ndkVersionDefine = SwiftSetting.define("ANDROID_NDK_VERSION_" + ndkVersion.description)

// Get Android API version
let sdkVersion = environment["ANDROID_SDK_VERSION"].flatMap { UInt($0) } ?? 28
let sdkVersionDefine = SwiftSetting.define("ANDROID_SDK_VERSION_" + sdkVersion.description)

let package = Package(
    name: "AndroidBluetooth",
    platforms: [
        .macOS(.v15),
        // Declared to match the Bluetooth/GATT/Socket dependencies. This package only ever builds
        // for Android, but SwiftPM validates platform requirements across the whole graph, and
        // leaving these unspecified defaults them to iOS 12 — which conflicts with dependencies
        // that require iOS 13 and breaks any Apple-platform resolve of a package that includes it.
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "AndroidBluetooth",
            targets: ["AndroidBluetooth"]),
        .library(
            name: "AndroidBluetoothBridge",
            targets: ["AndroidBluetoothBridge"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Android.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            from: "4.0.0"
        ),
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            from: "8.0.0"
        ),
        .package(
            url: "https://github.com/swift-android-sdk/swift-android-native.git",
            from: "2.1.0"
        ),
        .package(
            url: "https://github.com/swiftlang/swift-java.git",
            branch: "main"
        )
    ],
    targets: [
        .target(
            name: "AndroidBluetooth",
            dependencies: [
                .product(
                    name: "Bluetooth",
                    package: "Bluetooth"
                ),
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth"
                ),
                .product(
                    name: "GATT",
                    package: "GATT"
                ),
                .product(
                    name: "AndroidOS",
                    package: "Android"
                ),
                .product(
                    name: "AndroidContent",
                    package: "Android"
                ),
                .product(
                    name: "AndroidUtil",
                    package: "Android"
                ),
                .product(
                    name: "AndroidApp",
                    package: "Android"
                ),
                .product(
                    name: "AndroidManifest",
                    package: "swift-android-native"
                )
            ],
            exclude: ["swift-java.config"],
            swiftSettings: [
              .swiftLanguageMode(.v5),
              ndkVersionDefine,
              sdkVersionDefine
            ],
            plugins: [
                //.plugin(name: "SwiftJavaPlugin", package: "swift-java")
            ]
        ),
        .target(
            name: "AndroidBluetoothBridge",
            dependencies: [
                "AndroidBluetooth",
                .product(
                    name: "SwiftJava",
                    package: "swift-java"
                )
            ],
            exclude: ["swift-java.config"],
            swiftSettings: [
              .swiftLanguageMode(.v5)
            ],
            plugins: [
                .plugin(name: "JExtractSwiftPlugin", package: "swift-java")
            ]
        )
    ]
)
