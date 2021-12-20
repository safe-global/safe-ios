import XCTest
@testable import Ethereum
import TestHelpers
import JsonRpc2
import Json

final class EthereumTests: XCTestCase {
    func testName() throws {
        XCTAssertEqual(EthRpc1.eth_getBalance.name, "eth_getBalance")
    }
}
