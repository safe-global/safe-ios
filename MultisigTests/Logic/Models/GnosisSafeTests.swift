//
//  GnosisSafeTests.swift
//  MultisigTests
//
//  Created by Dmitry Bespalov on 20.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class GnosisSafeTests: XCTestCase {

    let someAddress: Address = "0x4995D78E5a672CC035929822E97EAcEB4464f97A"
    let safe = GnosisSafe()

    func testContractVersions() {
        XCTAssertEqual(safe.version(masterCopy: Address.zero), .unknown)
        XCTAssertEqual(safe.version(masterCopy: someAddress), .unknown)

        let oldVersion = safe.versions.first!
        XCTAssertEqual(safe.version(masterCopy: oldVersion.masterCopy), .upgradeAvailable(oldVersion.version))

        let newestVersion = safe.versions.last!
        XCTAssertEqual(safe.version(masterCopy: newestVersion.masterCopy), .upToDate(newestVersion.version))
    }

    func testSingleVersionsArray() {
        safe.versions = [(someAddress, "0.1.0")]
        let singleVersion = safe.versions.first!
        XCTAssertEqual(safe.version(masterCopy: singleVersion.masterCopy), .upToDate(singleVersion.version))
    }

    func testEmpty() {
        safe.versions = []
        XCTAssertEqual(safe.version(masterCopy: someAddress), .unknown)
    }

    func testSupportedVersions() {
        let supported: [Address] = [
            "0xb6029EA3B2c51D09a50B53CA8012FeEB05bDa35A",
            "0xaE32496491b53841efb51829d6f886387708F99B",
            "0x34CfAC646f301356fAa8B21e94227e3583Fe3F5F",
        ]

        let notSupported: [Address] = [
            "0xAC6072986E985aaBE7804695EC2d8970Cf7541A2",
            "0x8942595A2dC5181Df0465AF0D7be08c8f23C93af",
        ]

        let unknown: [Address] = [
            "0x3b1c2b0940C85458197E0D18690805d6F89547eE",
            "0x976DC99c50B916Ea9b5275979059BCe9f1A0B1D1",
            "0xD5D4763AE65aFfFD82e3aEe3ec9f21171A1d6e0e",
        ]

        for v in supported {
            XCTAssertTrue(safe.isSupported(v), "Expected to support \(v)")
        }

        for v in notSupported + unknown {
            XCTAssertFalse(safe.isSupported(v), "Expected NOT to support \(v)")
        }
    }

}
