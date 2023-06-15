//
//  DefaultSignerFactory.swift
//  Multisig
//
//  Created by Dirk Jäckel on 16.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import CryptoSwift
import SafeWeb3
import Auth

public struct DummySignerFactory: SignerFactory {

    public func createEthereumSigner() -> EthereumSigner {
        return Web3Signer()
    }
}

public struct Web3Signer: EthereumSigner {
    enum Web3Signer: Error {
      case shouldNotBeCalledError
    }
    public func sign(message: Data, with key: Data) throws -> EthereumSignature {
        throw Web3Signer.shouldNotBeCalledError
    }

    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        throw Web3Signer.shouldNotBeCalledError
    }

    public func keccak256(_ data: Data) -> Data {
        return Data()
    }
}
