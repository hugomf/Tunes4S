//
//  Tunes4STests.swift
//  Tunes4STests
//
//  Created by Jules on 11/18/25.
//

import XCTest
@testable import Tunes4S

class Tunes4STests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testColorExtensionWith6DigitHex() {
        let hex = "1DB954"
        let color = Color(hex: hex)
        let expectedColor = Color(red: 0.11372549019607843, green: 0.7254901960784313, blue: 0.32941176470588235)
        XCTAssertEqual(color.description, expectedColor.description)
    }

    func testColorExtensionWith3DigitHex() {
        let hex = "F0C"
        let color = Color(hex: hex)
        let expectedColor = Color(red: 1.0, green: 0.0, blue: 0.8, opacity: 1.0)
        XCTAssertEqual(color.description, expectedColor.description)
    }

    func testColorExtensionWithInvalidHex() {
        let hex = "INVALID"
        let color = Color(hex: hex)
        let expectedColor = Color(red: 0, green: 0, blue: 0)
        XCTAssertEqual(color.description, expectedColor.description)
    }

    func testWinampPlayerView_Initialization() {
        let view = WinampPlayerView()
        XCTAssertNotNil(view, "WinampPlayerView should initialize successfully.")
        XCTAssertNotNil(view.body, "The body of WinampPlayerView should not be nil.")
    }

    func testAudioService_Initialization() {
        let audioService = AudioService()
        XCTAssertNotNil(audioService, "AudioService should initialize successfully.")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
