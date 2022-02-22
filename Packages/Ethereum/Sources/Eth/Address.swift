//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity

extension Sol.Address: NodeDataCodable {
    public init(decoding data: Data) throws {
        try self.init(data: data)
    }

    public func encodeNodeData() throws -> Data {
        // we need to return 20-byte value. Address is ABI-encoded as UInt160, so we need to get the suffix.
        let result = encode().suffix(20)
        return result
    }
}