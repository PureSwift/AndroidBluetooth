// swift-tools-version:6.2
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
    ],
    dependencies: [
        .package(
            url: "https://github.com/PureSwift/Android.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/GATT.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/PureSwift/Bluetooth.git",
            from: "7.2.0"
        ),
        // `AndroidManifest` moved out of PureSwift/Android into swift-android-native (Android PR
        // #40); it must now be depended on directly. The URL and branch must match the ones
        // PureSwift/Android and skip-android-bridge use, or the identity conflicts.
        .package(
            url: "https://github.com/MillerTechnologyPeru/swift-android-native.git",
            branch: "feature/pureswift"
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
        )
    ]
)
