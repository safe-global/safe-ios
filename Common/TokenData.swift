//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import BigInt

// TODO: unit tests needed
public struct TokenData: Equatable, Hashable {

    /// Ethereum address of the token
    public let address: String
    /// Short abbreviation code of the token name
    public let code: String
    /// Full name of the token
    public let name: String
    /// Image URL of the token
    public let logoURL: URL?
    /// Maximum number of digits after the decimal point
    public let decimals: Int
    /// Account balance of the token measured in token units
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

    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }

    public var isEther: Bool {
        return address == "0x0" || address == "0x0000000000000000000000000000000000000000"
    }

    public func withBalance(_ balance: BigInt?) -> TokenData {
        return TokenData(address: address,
                         code: code,
                         name: name,
                         logoURL: logoURL?.absoluteString ?? "",
                         decimals: decimals,
                         balance: balance)
    }

    public func isSameToken(with other: TokenData) -> Bool {
        return address == other.address
    }

    fileprivate func withNonNegativeBalance() -> TokenData {
        return TokenData(address: address,
                         code: code,
                         name: name,
                         logoURL: logoURL?.absoluteString ?? "",
                         decimals: decimals,
                         balance: abs(balance))
    }

}

public func subtract(_ lhs: BigInt?, _ rhs: TokenData) -> BigInt? {
    guard let balance = lhs, let value = rhs.balance else { return  nil }
    return balance - value
}

public func subtract(_ lhs: BigInt?, _ rhs: BigInt?) -> BigInt? {
    guard let lhs = lhs, let rhs = rhs else { return  nil }
    return lhs - rhs
}

public func abs(_ value: BigInt?) -> BigInt? {
    guard let value = value else { return nil }
    return Swift.abs(value)
}

public func abs(_ value: TokenData) -> TokenData {
    return value.withNonNegativeBalance()
}
