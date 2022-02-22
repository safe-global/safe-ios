//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation
import Solidity
import JsonRpc2

public class NodeAccountMethod<ReturnType>: JsonRpc2MethodWithCompletion, Codable where ReturnType: Codable {
    public var address: NodeData<Sol.Address>
    public var block: NodeBlockId
    public var completion: (Result<ReturnType, Error>) -> Void = { _ in }

    public init(address: NodeData<Sol.Address>, block: NodeBlockId, completion: @escaping (Result<ReturnType, Error>) -> () = {  _ in }) {
        self.address = address
        self.block = block
        self.completion = completion
    }

    public convenience init<T>(address: Sol.Address, block: NodeBlockId, completion: @escaping (Result<T, Error>) -> ()) where T: FixedWidthInteger, ReturnType == NodeQuantity<T> {
        self.init(
                address: NodeData(address),
                block: block,
                completion: wrap(completion: completion)
        )
    }

    public convenience init<T>(address: Sol.Address, block: NodeBlockId, completion: @escaping (Result<T, Error>) -> ()) where T: NodeDataCodable, ReturnType == NodeData<T> {
        self.init(
                address: NodeData(address),
                block: block,
                completion: wrap(completion: completion)
        )
    }

    required public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        address = try container.decode(NodeData<Sol.Address>.self)
        block = try container.decode(NodeBlockId.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(address)
        try container.encode(block)
    }
}