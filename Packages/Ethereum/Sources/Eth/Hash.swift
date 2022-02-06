//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

public struct Hash {
    public init(storage: Sol.Bytes32) {
        self.storage = storage
    }

    public var storage: Sol.Bytes32
}

extension Hash: NodeDataCodable {
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