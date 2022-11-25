// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "AndroidBluetooth",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13),
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
            .upToNextMajor(from: "6.0.0")
        )
    ],
    targets: [
        .target(
            name: "AndroidBluetooth",
            dependencies: [
                "Android",
                "Bluetooth",
                "GATT",
                .product(
                    name: "BluetoothGAP",
                    package: "Bluetooth"
                )
            ]),
        .testTarget(
            name: "AndroidBluetoothTests",
            dependencies: ["AndroidBluetooth"]
        )
    ]
)
