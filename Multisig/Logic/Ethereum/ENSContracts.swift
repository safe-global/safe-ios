//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

class ENSRegistry: Contract {
    func resolver(node: Data) throws -> Address {
        try decodeAddress(invoke("resolver(bytes32)", encodeFixedBytes(node)))
    }
}

class ENSResolver: Contract {
    enum Selectors {
        public static let supportsInterface = "supportsInterface(bytes4)"
        public static let address = "addr(bytes32)"
        public static let name = "name(bytes32)"
    }

    func supportsInterface(_ selector: String) throws -> Bool {
        try decodeBool(invoke(Selectors.supportsInterface,
                              encodeFixedBytes(method(selector))))
    }

    func address(node: Data) throws -> Address {
        try decodeAddress(invoke(Selectors.address, encodeFixedBytes(node)))
    }

    func name(node: Data) throws -> String? {
        try decodeString(invoke(Selectors.name, encodeFixedBytes(node)))
    }
}

class ENSReverseResolver: Contract {
    func name(node: Data) throws -> String? {
        try decodeString(invoke("name(bytes32)", encodeFixedBytes(node)))
    }
}
