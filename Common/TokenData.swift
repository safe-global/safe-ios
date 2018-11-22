//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import BigInt

// TODO: unit tests needed
public struct TokenData: Equatable, Hashable {

    public let address: String
    public let code: String
    public let name: String
    public let logoURL: URL?
    public let decimals: Int
    public let balance: BigInt?

    public static let Ether = TokenData(address: "0x0000000000000000000000000000000000000000",
                                        code: "ETH",
                                        name: "Ether",
                                        logoURL: "",
                                        decimals: 18,
                                        balance: 0)

    public init(address: String, code: String, name: String, logoURL: String, decimals: Int, balance: BigInt?) {
        self.address = address
        self.code = code
        self.name = name
        self.logoURL = logoURL.isEmpty ? nil : URL(string: logoURL)
        self.decimals = decimals
        self.balance = balance
    }

    public var hashValue: Int {
        return address.hashValue
    }

    public var isEther: Bool {
        return address == "0x0" || address == "0x0000000000000000000000000000000000000000"
    }

    public func withBalance(_ balance: BigInt) -> TokenData {
        return TokenData(address: address,
                         code: code,
                         name: name,
                         logoURL: logoURL?.absoluteString ?? "",
                         decimals: decimals,
                         balance: balance)
    }

    public func isSameToken(with other: TokenData) -> Bool {
        return address == other.address &&
            code == other.code &&
            name == other.name &&
            logoURL == other.logoURL &&
            decimals == other.decimals
    }

}
