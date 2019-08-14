//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Common

class TrackerTests: XCTestCase {

    var tracker = Tracker()
    var handler = TestHandler()

    override func setUp() {
        super.setUp()
        tracker.append(handler: handler)
    }

    func test_whenAddingHandler_thenReceivesEvent() {
        tracker.track(event: TestEvent.test)
        tracker.track(event: TestEvent.test)
        XCTAssertEqual(handler.events.map { $0.event }, [TestEvent.test.rawValue, TestEvent.test.rawValue])
    }

    func test_whenAddingTwice_thenDoesNotDuplicate() {
        tracker.append(handler: handler)
        tracker.track(event: TestEvent.test)
        XCTAssertEqual(handler.events.map { $0.event }, [TestEvent.test.rawValue])
    }

    func test_whenEventWithParams_thenPassesParamsToHandler() {
        tracker.track(event: TestParamEvent())
        let params = handler.events.compactMap { $0.parameters }.first
        XCTAssertEqual(params?["param"] as? String, "value")
    }

    func test_whenParamsWithDifferentKeys_thenMergesThem() {
        tracker.track(event: TestParamEvent(), parameters: ["other": "otherValue"])
        let params = handler.events.compactMap { $0.parameters }.first
        XCTAssertEqual(params?["param"] as? String, "value")
        XCTAssertEqual(params?["other"] as? String, "otherValue")
    }

    func test_whenParamsWithSameKeys_thenOverridesEventParams() {
        tracker.track(event: TestParamEvent(), parameters: ["param": "otherValue"])
        let params = handler.events.compactMap { $0.parameters }.first
        XCTAssertEqual(params?["param"] as? String, "otherValue")
    }

    func test_whenEmptyParams_thenReceivesNilParams() {
        tracker.track(event: TestEvent.test, parameters: [:])
        let event = handler.events.first!
        XCTAssertNil(event.parameters)
    }

    func test_whenRemovingHandler_thenRemovesIt() {
        tracker.remove(handler: handler)
        tracker.track(event: TestEvent.test)
        XCTAssertTrue(handler.events.isEmpty)
    }

}

enum TestEvent: String, Trackable, Equatable {

    case test = "Test"

}

struct TestParamEvent: Trackable {

    var rawValue: String { return "test" }
    var eventName: String { return "param_event" }
    var parameters: [String: Any]? { return ["param": "value"] }

}

class TestHandler: TrackingHandler {

    var events: [(event: String, parameters: [String: Any]?)] = []

    func track(event: String, parameters: [String: Any]?) {
        events.append((event, parameters))
    }

}
