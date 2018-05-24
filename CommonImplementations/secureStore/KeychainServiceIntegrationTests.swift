//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import CommonImplementations
import Common

class KeychainServiceIntegrationTests: XCTestCase {

    let data = Data(repeating: 7, count: 32)
    let keychainService = KeychainService(identifier: "KeychainIntegrationTest")

    override func setUp() {
        super.setUp()
        try? keychainService.destroy()
    }

    func test_whenCreated_thenCanBeDestroyed() {
        XCTAssertNoThrow(try keychainService.save(data: data, forKey: "testKey"))
        XCTAssertNoThrow(try keychainService.save(data: data, forKey: "testKey1"))
        XCTAssertNoThrow(try keychainService.destroy())
        XCTAssertNil(try keychainService.data(forKey: "testKey"))
        XCTAssertNil(try keychainService.data(forKey: "testKey1"))
    }

    func test_whenSaved_thenCanFetch() {
        XCTAssertNoThrow(try keychainService.save(data: data, forKey: "testKey"))
        var savedData: Data? = nil
        XCTAssertNoThrow(savedData = try keychainService.data(forKey: "testKey"))
        XCTAssertEqual(savedData, data)
    }

    func test_whenRemoved_thenCanNotFind() {
        XCTAssertNoThrow(try keychainService.save(data: data, forKey: "testKey"))
        XCTAssertNoThrow(try keychainService.removeData(forKey: "testKey"))
        XCTAssertNil(try keychainService.data(forKey: "testKey"))
    }

}
