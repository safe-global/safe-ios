//
//  JsonRpc2Tests.swift
//  JsonRpc2Tests
//
//  Created by Dmitry Bespalov on 15.12.21.
//

import XCTest
@testable import JsonRpc2
import TestHelpers

class JsonRpc2TestCase: XCTestCase {

    func testCodable() throws {
        // Note: keys are sorted alphabetically in these tests so that the order is deterministic in encoding.

        // rpc call with positional parameters
        try assert(JsonRpc2.Request.self,
        """
        {"id":1,"jsonrpc":"2.0","method":"subtract","params":[42,23]}
        """)

        try assert(JsonRpc2.Response.self,
        """
        {"id":1,"jsonrpc":"2.0","result":19}
        """
        )

        // rpc call with named parameters
        try assert(JsonRpc2.Request.self,
        """
        {"id":3,"jsonrpc":"2.0","method":"subtract","params":{"minuend":42,"subtrahend":23}}
        """
        )

        // a notification
        try assert(JsonRpc2.Request.self,
        """
        {"jsonrpc":"2.0","method":"update","params":[1,2,3,4,5]}
        """
        )

        // a notification
        try assert(JsonRpc2.Request.self,
        """
        {"jsonrpc":"2.0","method":"foobar"}
        """
        )

        // error response
        try assert(JsonRpc2.Response.self,
        """
        {"error":{"code":-32601,"message":"Method not found"},"id":"1","jsonrpc":"2.0"}
        """
        )

        // invalid request json:
        XCTAssertThrowsError(
        try assert(JsonRpc2.Request.self,
        """
        {"jsonrpc": "2.0", "method": "foobar, "params": "bar", "baz]
        """
        )
        ) { error in
            if let err = error as? DecodingError {
                switch err {
                case .dataCorrupted(_):
                    // ok!
                    break
                default:
                    XCTFail("Unexpected error: \(error)")
                }
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // invalid request (params is primitive)
        XCTAssertThrowsError(
        try assert(JsonRpc2.Request.self,
        """
        {"jsonrpc": "2.0", "method": 1, "params": "bar"}
        """
        )
        ) { error in
            if let err = error as? DecodingError {
                switch err {
                case .typeMismatch(_, _):
                    // ok!
                    break
                default:
                    XCTFail("Unexpected error: \(error)")
                }
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func testBatch() throws {
        // rpc call Batch, invalid JSON
        XCTAssertThrowsError(
        try assert(JsonRpc2.BatchRequest.self,
        """
        [
          {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
          {"jsonrpc": "2.0", "method"
        ]
        """
        )
        ) { error in
            if let err = error as? DecodingError {
                switch err {
                case .dataCorrupted(_):
                    // ok!
                    break
                default:
                    XCTFail("Unexpected error: \(error)")
                }
            } else {
                XCTFail("Unexpected error: \(error)")
            }
        }

        // invalid empty batch
        XCTAssertThrowsError(
        try assert(JsonRpc2.BatchRequest.self,
        "[]"
        )
        ) { error in
            if let error = error as? JsonRpc2.Error {
                XCTAssertEqual(error.code, -32600)
            }
        }

        // rpc call with an invalid Batch (but not empty):
        XCTAssertThrowsError(
        try assert(JsonRpc2.BatchRequest.self,
        "[1]"
        )
        ) { error in
            if let error = error as? JsonRpc2.Error {
                XCTAssertEqual(error.code, -32600)
            }
        }

        // rpc call with invalid Batch
        XCTAssertThrowsError(
        try assert(JsonRpc2.BatchRequest.self,
        "[1,2,3]"
        )
        ) { error in
            if let error = error as? JsonRpc2.Error {
                XCTAssertEqual(error.code, -32600)
            }
        }

        // rpc call Batch:
        let batchWithInvalid: JsonRpc2.BatchRequest = try decode(from:
        """
        [
            {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
            {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]},
            {"jsonrpc": "2.0", "method": "subtract", "params": [42,23], "id": "2"},
            {"foo": "boo"},
            {"jsonrpc": "2.0", "method": "foo.get", "params": {"name": "myself"}, "id": "5"},
            {"jsonrpc": "2.0", "method": "get_data", "id": "9"}
        ]
        """
        )
        try XCTAssertEqual(
        """
        [{"id":"1","jsonrpc":"2.0","method":"sum","params":[1,2,4]},{"jsonrpc":"2.0","method":"notify_hello","params":[7]},{"id":"2","jsonrpc":"2.0","method":"subtract","params":[42,23]},null,{"id":"5","jsonrpc":"2.0","method":"foo.get","params":{"name":"myself"}},{"id":"9","jsonrpc":"2.0","method":"get_data"}]
        """,
        encode(value: batchWithInvalid))


        // rpc response Batch:
        try assert(JsonRpc2.BatchResponse.self,
        """
        [{"id":"1","jsonrpc":"2.0","result":7},{"id":"2","jsonrpc":"2.0","result":19},{"error":{"code":-32600,"message":"Invalid Request"},"id":null,"jsonrpc":"2.0"},{"error":{"code":-32601,"message":"Method not found"},"id":"5","jsonrpc":"2.0"},{"id":"9","jsonrpc":"2.0","result":["hello",5]}]
        """
        )
    }

    func assert<T: Codable>(_ type: T.Type, _ string: String) throws {
        let request: T = try decode(from: string)
        try XCTAssertEqual(string, encode(value: request))
    }
}
