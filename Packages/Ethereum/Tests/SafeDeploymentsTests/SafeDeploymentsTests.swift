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
    }
}
