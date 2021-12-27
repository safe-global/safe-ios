//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 23.12.21.
//

import Foundation
import XCTest
@testable import Solidity

class SolAbiSignedIntegerTests: XCTestCase {
    typealias i256 = SolAbi.Int256

    func testSmoke() {
        XCTAssertEqual(i256(0), 0)
        XCTAssertEqual(i256(-1), -1)
        XCTAssertEqual(i256(1), 1)

        // boundaries
        XCTAssertEqual(i256.max.storage,
                       SolAbi.UInt256("7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", radix: 16))
        XCTAssertEqual(i256.min.storage,
                       SolAbi.UInt256("8000000000000000000000000000000000000000000000000000000000000000", radix: 16))

    }

    // sign extension
    func testWords() {
        XCTAssertEqual(i256(-1).words, [0xffff_ffff_ffff_ffff,
                                        0xffff_ffff_ffff_ffff,
                                        0xffff_ffff_ffff_ffff,
                                        0xffff_ffff_ffff_ffff])

        XCTAssertEqual(i256(-7).words, [0xffff_ffff_ffff_fff9,
                                        0xffff_ffff_ffff_ffff,
                                        0xffff_ffff_ffff_ffff,
                                        0xffff_ffff_ffff_ffff])

        XCTAssertEqual(i256(7).words,  [7, 0, 0, 0])
    }
    
    func testSignum() {
        // sign
        XCTAssertEqual(i256(-7).signum(), -1)
        XCTAssertEqual(i256(7).signum(), 1)
        XCTAssertEqual(i256(0).signum(), 0)
        XCTAssertEqual(i256.max.signum(), +1)
        XCTAssertEqual(i256.min.signum(), -1)
    }

    func testByteSwapped() {
        XCTAssertEqual(i256(-7).byteSwapped.words,
                       [0xffff_ffff_ffff_ffff,
                        0xffff_ffff_ffff_ffff,
                        0xffff_ffff_ffff_ffff,
                        0xf9ff_ffff_ffff_ffff])
        XCTAssertEqual(i256(7).byteSwapped.words,  [0, 0, 0, 0x0700_0000_0000_0000])
    }

    func testInitString() {
        XCTAssertEqual(i256("-15"), i256(-15))
    }
}
