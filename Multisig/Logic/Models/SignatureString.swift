//
//  SignatureString.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 30.09.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation

struct SignatureString: Hashable, Decodable {
    let signature: Data

    enum SignatureStringError: String, Error {
        case wrongSignatureLength = "Signature length should be 65 bytes"
    }

    init(_ signature: Data) {
        self.signature = signature
    }

    init(hex: String) throws {
        let data: Data = Data(hex: hex)
        guard data.count == 65 else { throw SignatureStringError.wrongSignatureLength }
        self.signature = data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(hex: string)
    }

}

extension SignatureString: CustomStringConvertible {
    var description: String {
        signature.toHexStringWithPrefix()
    }
}
