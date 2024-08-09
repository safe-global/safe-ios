//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 04.01.22.
//

import Foundation
import SafeDeployments
import XCTest

class SafeDeploymentsTests: XCTestCase {
    func testFind_GnosisSafe_L2_1_3_0() throws {
        guard let gs = try Safe.Deployment.find(contract: .GnosisSafeL2, version: .v1_3_0) else {
            XCTFail("Resource not found")
            return
        }
        XCTAssertEqual(gs.contractName, "GnosisSafeL2")
        // "canonical"
        XCTAssertEqual(gs.address(for: "1"), "0x3E5c63644E683549055b9Be8653de26E0B4CD36E")
        // "eip155"
        XCTAssertEqual(gs.address(for: "18"), "0xfb1bffC9d739B8D520DaF37dF666da4C687191EA")
        // "zksync"
        XCTAssertEqual(gs.address(for: "280"), "0x1727c2c531cf966f902E5927b98490fDFb3b2b70")
    }
}
