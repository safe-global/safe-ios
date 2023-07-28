//
//  NullCryptoProvider.swift
//  Multisig
//
//  Created by Dirk Jäckel on 16.03.23.
//  Copyright © 2023 Gnosis Ltd. All rights reserved.
//

import Foundation
import WalletConnectSigner

// The `CryptoProvider` implementation is a no-op
// because it is used in the App actor, not in the Wallet role
public struct NullCryptoProvider: CryptoProvider {
    public enum ProviderError: Error {
      case shouldNotBeCalledError
    }

    public func recoverPubKey(signature: EthereumSignature, message: Data) throws -> Data {
        throw ProviderError.shouldNotBeCalledError
    }

    public func keccak256(_ data: Data) -> Data {
        return Data()
    }
}
