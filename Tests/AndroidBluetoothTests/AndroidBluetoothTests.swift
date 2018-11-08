import XCTest
@testable import AndroidBluetooth

final class AndroidBluetoothTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(AndroidBluetooth().text, "Hello, World!")
    }


    static var allTests = [
        ("testExample", testExample),
    ]
}
