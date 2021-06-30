//
//  UIColorStylesTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 30.06.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig
import UIKit

class UIColorStylesTests: XCTestCase {

    func test_initHex() {
        // #rrggbb -> rr gg bb
        XCTAssertEqual(UIColor(hex: "#aa0099"), UIColor(
                        red: CGFloat(0xaa) / 0xff,
                        green: CGFloat(0x00) / 0xff,
                        blue: CGFloat(0x99) / 0xff,
                        alpha: 1.0
        ))

        // invalid
        XCTAssertNil(UIColor(hex: "0x123"), "Invalid prefix: 0x")
        XCTAssertNil(UIColor(hex: "#aa"), "Invalid number of symbols: 2")
        XCTAssertNil(UIColor(hex: "#12345"), "Invalid number of symbols: 5")
        XCTAssertNil(UIColor(hex: "#1234567"), "Invalid number of symbols: 7")
        XCTAssertNil(UIColor(hex: "#123456789"), "Invalid number of symbols: 9")
        XCTAssertNil(UIColor(hex: "#xxx"), "Invalid hex symbol: xx")

        // NOTE: we agreed to implement only rrggbb format for now because it is supported by all
        // platforms (web, Android, and iOS)
        XCTAssertNil(UIColor(hex: "#a09"), "Invalid format: rgb")
        XCTAssertNil(UIColor(hex: "#af38"), "Invalid format: rgba or argb")
        XCTAssertNil(UIColor(hex: "#aaff3388"), "Invalid format: rrggbbaa or aarrggbb")
    }
}
