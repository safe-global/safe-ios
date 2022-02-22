//
// Created by Dmitry Bespalov on 06.02.22.
//

import Foundation

extension Data: NodeDataCodable {
    public func encodeNodeData() throws -> Data {
        self
    }

    public init(decoding data: Data) throws {
        self = data
    }
}