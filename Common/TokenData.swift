//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import BigInt

public struct TokenData: Equatable, Hashable {

    public let address: String
    public let code: String
    public let name: String
    public let logoURL: URL?
    public let decimals: Int
    public let balance: BigInt?

    public init(address: String, code: String, name: String, logoURL: String, decimals: Int, balance: BigInt?) {
        self.address = address
        self.code = code
        self.name = name
        self.logoURL = URL(string: logoURL)
        self.decimals = decimals
        self.balance = balance
    }

    public var hashValue: Int {
        return address.hashValue
    }

}

public extension TokenData {

    var isEther: Bool {
        return address == "0x0" || address == "0x0000000000000000000000000000000000000000"
    }

}
