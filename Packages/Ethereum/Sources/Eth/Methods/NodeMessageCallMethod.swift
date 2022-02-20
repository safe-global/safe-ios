//
// Created by Dmitry Bespalov on 20.02.22.
//

import Foundation
import JsonRpc2
import Json
import Solidity

extension Node {
    public class NodeMessageCallMethod<ReturnType>: JsonRpc2MethodWithCompletion, Codable where ReturnType: Codable {
        public var message: MessageCall
        public var block: NodeBlockId
        public var completion: (Result<ReturnType, Error>) -> Void = { _ in }

        public init(message: MessageCall, block: NodeBlockId, completion: @escaping (Result<ReturnType, Error>) -> ()) {
            self.message = message
            self.block = block
            self.completion = completion
        }

        public convenience init<T>(message: MessageCall, block: NodeBlockId, completion: @escaping (Result<T, Error>) -> ()) where T: FixedWidthInteger, ReturnType == NodeQuantity<T> {
            self.init(
                    message: message,
                    block: block,
                    completion: wrap(completion: completion)
            )
        }

        public convenience init<T>(message: MessageCall, block: NodeBlockId, completion: @escaping (Result<T, Error>) -> ()) where T: NodeDataCodable, ReturnType == NodeData<T> {
            self.init(
                    message: message,
                    block: block,
                    completion: wrap(completion: completion)
            )
        }

        required public init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            message = try container.decode(MessageCall.self)
            block = try container.decode(NodeBlockId.self)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()
            try container.encode(message)
            try container.encode(block)
        }

    }
}
