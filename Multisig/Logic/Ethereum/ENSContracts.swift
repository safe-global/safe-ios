//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

class ENSRegistry: Contract {
    func resolver(node: Data) throws -> Address {
        try decodeAddress(invoke("resolver(bytes32)", encodeFixedBytes(node)))
    }
}

class ENSResolver: ERC165 {
    enum Selectors {
        public static let address = "addr(bytes32)"
        public static let name = "name(bytes32)"
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

class EthRegistrar: Contract {

    static let address: Address = "0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85"

    func ens() throws -> Address {
        try decodeAddress(invoke("ens()"))
    }

}

class ERC165: Contract {

    enum Selectors {
        public static let supportsInterface = "supportsInterface(bytes4)"
    }

    func supportsInterface(_ selector: String) throws -> Bool {
        try decodeBool(invoke(Selectors.supportsInterface,
                              encodeFixedBytes(method(selector))))
    }

}
