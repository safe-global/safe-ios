//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

public struct WalletData: Equatable {

    public enum State {
        case pending
        case created
    }

    public let address: String
    public let name: String
    public let state: State

    public init(address: String, name: String, state: State) {
        self.address = address
        self.name = name
        self.state = state
    }

}
