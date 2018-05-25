//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Common

class InMemorySecureStoreTests: XCTestCase {

    func test_all() throws {
        let store = InMemorySecureStore()
        let data = Data(repeating: 3, count: 3)
        try store.save(data: data, forKey: "test")
        XCTAssertEqual(try store.data(forKey: "test"), data)
        try store.removeData(forKey: "test")
        XCTAssertNil(try store.data(forKey: "test"))
        try store.save(data: data, forKey: "other")
        try store.save(data: data, forKey: "another")
        try store.destroy()
        XCTAssertNil(try store.data(forKey: "other"))
        XCTAssertNil(try store.data(forKey: "another"))
    }

}
