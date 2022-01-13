import XCTest
@testable import Ethereum
import TestHelpers
import JsonRpc2
import Json
import Solidity

final class EthereumTests: XCTestCase {
    func testName() throws {
        XCTAssertEqual(EthRpc1.eth_getBalance.name, "eth_getBalance")
    }

    func testTokenAmount() {
        let a = Eth.TokenAmount<Sol.UInt256>(value: 1, decimals: 18, symbol: "E")
        // 1e18 = 1000e15
        XCTAssertEqual(a.converted(to: 15).value, 1000)
        // 1e18 = 0e19
        XCTAssertEqual(a.converted(to: 19).value, 0)

        // 10e18 = 1e19
        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>(value: 10, decimals: 18, symbol: "E").converted(to: 19).value, 1)

        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>(value: 10, decimals: 18, symbol: "E"),
                       Eth.TokenAmount<Sol.UInt256>(value: 1, decimals: 19, symbol: "E"))
    }

    func testFormatting() {
        let a = Eth.TokenAmount<Sol.UInt256>(value: 1, decimals: 18, symbol: "E")
        XCTAssertEqual(String(a), "0.000000000000000001 E")

        XCTAssertEqual(String(Eth.TokenAmount<Sol.UInt256>(value: 1, decimals: 3)), "0.001")
        XCTAssertEqual(String(Eth.TokenAmount<Sol.UInt256>(value: 100001, decimals: 3)), "100.001")
        XCTAssertEqual(String(Eth.TokenAmount<Sol.UInt256>(value: 100, decimals: 3)), "0.1")
        XCTAssertEqual(String(Eth.TokenAmount<Sol.UInt256>(value: 10, decimals: 3)), "0.01")
        XCTAssertEqual(String(Eth.TokenAmount<Sol.UInt256>(value: 0, decimals: 3)), "0")
        XCTAssertEqual(String(Eth.TokenAmount<Sol.UInt256>(value: 1000, decimals: 3)), "1")
        XCTAssertEqual(String(Eth.TokenAmount<Sol.UInt256>(value: 5000, decimals: 3)), "5")
        XCTAssertEqual(String(Eth.TokenAmount<Sol.UInt256>(value: 50000, decimals: 3)), "50")
    }

    func testInitFromString() {
        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>(" 0.001  E ", radix: 10, decimals: 3),
                       Eth.TokenAmount<Sol.UInt256>(value: 1, decimals: 3, symbol: "E"))

        XCTAssertNil(Eth.TokenAmount<Sol.UInt256>("0.001 E 4", radix: 10, decimals: 3))
        XCTAssertNil(Eth.TokenAmount<Sol.UInt256>("", radix: 10, decimals: 3))
        XCTAssertNil(Eth.TokenAmount<Sol.UInt256>(" E", radix: 10, decimals: 3))

        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>("1  E", radix: 10, decimals: 3),
                       Eth.TokenAmount<Sol.UInt256>(value: 1000, decimals: 3, symbol: "E"))

        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>("10  E", radix: 10, decimals: 3),
                       Eth.TokenAmount<Sol.UInt256>(value: 10000, decimals: 3, symbol: "E"))

        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>(".1  E", radix: 10, decimals: 3),
                       Eth.TokenAmount<Sol.UInt256>(value: 100, decimals: 3, symbol: "E"))
        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>("0.1  E", radix: 10, decimals: 3),
                       Eth.TokenAmount<Sol.UInt256>(value: 100, decimals: 3, symbol: "E"))

        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>(".01  E", radix: 10, decimals: 3),
                       Eth.TokenAmount<Sol.UInt256>(value: 10, decimals: 3, symbol: "E"))
        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>("0.01  E", radix: 10, decimals: 3),
                       Eth.TokenAmount<Sol.UInt256>(value: 10, decimals: 3, symbol: "E"))

        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>(".001  E", radix: 10, decimals: 3),
                       Eth.TokenAmount<Sol.UInt256>(value: 1, decimals: 3, symbol: "E"))
        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>("0.001  E", radix: 10, decimals: 3),
                       Eth.TokenAmount<Sol.UInt256>(value: 1, decimals: 3, symbol: "E"))

        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>(".0001  E", radix: 10, decimals: 3),
                       nil)
        XCTAssertEqual(Eth.TokenAmount<Sol.UInt256>("0.0001  E", radix: 10, decimals: 3),
                       nil)

        let amount = Eth.TokenAmount<Sol.UInt256>("0.000000012", radix: 10, decimals: 9)
        XCTAssertNotNil(amount)


        // overflow
        XCTAssertEqual(Eth.TokenAmount<Sol.UInt8>("256", radix: 10, decimals: 3),
                       nil)
    }
}
