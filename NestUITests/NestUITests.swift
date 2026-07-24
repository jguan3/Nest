//
//  NestUITests.swift
//  NestUITests
//
//  Created by 57 BGCC Loan Library on 7/7/26.
//

import XCTest

final class NestUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testFirstLaunchOnboardingFlowPersistsCompletion() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetOnboarding"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Welcome to Nested 👋"].waitForExistence(timeout: 3))
        app.buttons["Start Tour"].tap()

        for expectedTitle in [
            "Daily Mood Check-In",
            "Reflect Freely",
            "Wellness Tools",
            "Look Back and Learn"
        ] {
            XCTAssertTrue(app.staticTexts[expectedTitle].waitForExistence(timeout: 2))
            app.buttons["Next"].tap()
        }

        XCTAssertTrue(app.staticTexts["You're all set 🌱"].waitForExistence(timeout: 2))
        app.buttons["Start Exploring"].tap()
        XCTAssertFalse(app.staticTexts["You're all set 🌱"].waitForExistence(timeout: 1))

        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertFalse(app.staticTexts["Welcome to Nested 👋"].waitForExistence(timeout: 1))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
