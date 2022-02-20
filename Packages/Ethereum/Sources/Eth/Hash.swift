//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity
import CryptoSwift

extension Node {
    public struct Hash: Hashable {
        public init(storage: Sol.Bytes32) {
            self.storage = storage
        }

        public var storage: Sol.Bytes32
    }
}

extension Node.Hash: NodeDataCodable {
    public init() {
        self.init(storage: .init())
    }

    public init(decoding data: Data) throws {
        storage = try Sol.Bytes32(data)
    }

    public func encodeNodeData() throws -> Data {
        storage.encode()
    }
}

extension Node.Hash: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        let data = Data(hex: value)
        storage = try! Sol.Bytes32(data)
    }

    public init(unicodeScalarLiteral value: String) {
        let data = Data(hex: value)
        storage = try! Sol.Bytes32(data)
    }
}
