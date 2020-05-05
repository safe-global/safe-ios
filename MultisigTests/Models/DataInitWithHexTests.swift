//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class DataInitWithHexTests: XCTestCase {

    func test_ethDataConversion() {
        XCTAssertEqual(Data(ethHex: "0x"), Data())
        XCTAssertEqual(Data(ethHex: "0X"), Data())
        XCTAssertEqual(Data(ethHex: "0xa"), Data([0x0a]))
        XCTAssertEqual(Data(ethHex: "0xbbb"), Data([0x0b, 0xbb]))
        XCTAssertEqual(Data(ethHex: "0x1234"), Data([0x12, 0x34]))
    }

    func test_padding() {
        XCTAssertEqual(Data([5]).leftPadded(to: 2, with: 1), Data([1, 5]))
        XCTAssertEqual(Data([5, 5, 5]).leftPadded(to: 2), Data([5, 5, 5]))
    }

}
