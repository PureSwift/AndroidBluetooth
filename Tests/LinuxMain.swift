import XCTest

import AndroidBluetoothTests

var tests = [XCTestCaseEntry]()
tests += AndroidBluetoothTests.allTests()
XCTMain(tests)