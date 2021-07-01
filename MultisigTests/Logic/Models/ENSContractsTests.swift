//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import XCTest
@testable import Multisig

class ENSContractsTests: XCTestCase {
    func test_resolverInterfaceIds() {
        let resolver = ENSResolver(.zero, rpcURL: URL(string: "https://example.com")!)
        XCTAssertEqual(resolver.method(ERC165.Selectors.supportsInterface), Data(hex: "0x01ffc9a7"))
        XCTAssertEqual(resolver.method(ENSResolver.Selectors.address), Data(hex: "0x3b3b57de"))
        XCTAssertEqual(resolver.method(ENSResolver.Selectors.name), Data(hex: "0x691f3431"))
    }
}
