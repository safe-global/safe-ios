//
//  File.swift
//  
//
//  Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import Solidity

extension SolAbiEncodable where Self: NodeDataCodable {
    public init(decoding data: Data) throws {
        self = try Self.init(data)
    }

    public func encodeNodeData() throws -> Data {
        encode()
    }
}

extension Sol.Bytes: NodeDataCodable {}

extension Sol.Bytes1: NodeDataCodable {}
extension Sol.Bytes2: NodeDataCodable {}
extension Sol.Bytes3: NodeDataCodable {}
extension Sol.Bytes4: NodeDataCodable {}
extension Sol.Bytes5: NodeDataCodable {}
extension Sol.Bytes6: NodeDataCodable {}
extension Sol.Bytes7: NodeDataCodable {}
extension Sol.Bytes8: NodeDataCodable {}
extension Sol.Bytes9: NodeDataCodable {}
extension Sol.Bytes10: NodeDataCodable {}
extension Sol.Bytes11: NodeDataCodable {}
extension Sol.Bytes12: NodeDataCodable {}
extension Sol.Bytes13: NodeDataCodable {}
extension Sol.Bytes14: NodeDataCodable {}
extension Sol.Bytes15: NodeDataCodable {}
extension Sol.Bytes16: NodeDataCodable {}
extension Sol.Bytes17: NodeDataCodable {}
extension Sol.Bytes18: NodeDataCodable {}
extension Sol.Bytes19: NodeDataCodable {}
extension Sol.Bytes20: NodeDataCodable {}
extension Sol.Bytes21: NodeDataCodable {}
extension Sol.Bytes22: NodeDataCodable {}
extension Sol.Bytes23: NodeDataCodable {}
extension Sol.Bytes24: NodeDataCodable {}
extension Sol.Bytes25: NodeDataCodable {}
extension Sol.Bytes26: NodeDataCodable {}
extension Sol.Bytes27: NodeDataCodable {}
extension Sol.Bytes28: NodeDataCodable {}
extension Sol.Bytes29: NodeDataCodable {}
extension Sol.Bytes30: NodeDataCodable {}
extension Sol.Bytes31: NodeDataCodable {}
extension Sol.Bytes32: NodeDataCodable {}

extension Sol.String: NodeDataCodable {}
extension Sol.Array: NodeDataCodable {}
extension Sol.FixedArray: NodeDataCodable {}
extension Sol.Tuple: NodeDataCodable {}
