//
//  JsonTests.swift
//  JsonRpc2Tests
//
//  Created by Dmitry Bespalov on 15.12.21.
//

import XCTest
@testable import Json
import TestHelpers
import Foundation

class JsonTests: XCTestCase {
    func testDecoding() throws {
        try XCTAssertEqual(decode("null"), .null)
        try XCTAssertEqual(decode("true"), .bool(true))
        try XCTAssertEqual(decode("false"), .bool(false))
        try XCTAssertEqual(decode("1"), .int(1))
        try XCTAssertEqual(decode("0"), .int(0))
        try XCTAssertEqual(decode("-1"), .int(-1))
        try XCTAssertEqual(decode("\(UInt.max)"), .uint(UInt.max))
        try XCTAssertEqual(decode("1.1"), .double(1.1))
        try XCTAssertEqual(decode("1.0"), .int(1))
        try XCTAssertEqual(decode("\"hello\""), .string("hello"))
        try XCTAssertEqual(decode("[]"), .array(Json.Array(elements: [])))
        try XCTAssertEqual(decode("{}"), .object(Json.Object(members: [:])))

        // array of primitives
        try XCTAssertEqual(decode("[null, \"hello\", 2, 3.3, -1, true]"),
                           .array(Json.Array(elements: [.null, .string("hello"), .int(2), .double(3.3), .int(-1), .bool(true)])))

        // array of arrays
        try XCTAssertEqual(decode("[[],[]]"), .array(Json.Array(elements: [
            .array(Json.Array(elements: [])),
            .array(Json.Array(elements: []))
        ])))

        // array of objects
        try XCTAssertEqual(decode("[{},{}]"), .array(Json.Array(elements: [
            .object(Json.Object(members: [:])),
            .object(Json.Object(members: [:]))
        ])))

        // object with arrays
        try XCTAssertEqual(decode("{\"key\": []}"), .object(Json.Object(members: ["key": .array(Json.Array(elements: []))])))

        // object with objects
        try XCTAssertEqual(decode("{\"key\": {}}"), .object(Json.Object(members: ["key": .object(Json.Object(members: [:]))])))
    }

    func testEncoding() throws {
        try XCTAssertEqual("null", encode(.null))
        try XCTAssertEqual("true", encode(.bool(true)))
        try XCTAssertEqual("false", encode(.bool(false)))
        try XCTAssertEqual("1", encode(.int(1)))
        try XCTAssertEqual("0", encode(.int(0)))
        try XCTAssertEqual("-1", encode(.int(-1)))
        try XCTAssertEqual("\(UInt.max)", encode(.uint(UInt.max)))
        try XCTAssertEqual("1.1000000000000001", encode(.double(1.1)))
        try XCTAssertEqual("\"hello\"", encode(.string("hello")))
        try XCTAssertEqual("[]", encode(.array(Json.Array(elements: []))))
        try XCTAssertEqual("{}", encode(.object(Json.Object(members: [:]))))

        // array of primitives
        try XCTAssertEqual("[null,\"hello\",2,3.2999999999999998,-1,true]",
                           encode(
                           .array(Json.Array(elements: [.null, .string("hello"), .int(2), .double(3.3), .int(-1), .bool(true)]))))

        // array of arrays
        try XCTAssertEqual("[[],[]]", encode(.array(Json.Array(elements: [
            .array(Json.Array(elements: [])),
            .array(Json.Array(elements: []))
        ]))))

        // array of objects
        try XCTAssertEqual("[{},{}]", encode(.array(Json.Array(elements: [
            .object(Json.Object(members: [:])),
            .object(Json.Object(members: [:]))
        ]))))

        // object with arrays
        try XCTAssertEqual("{\"key\":[]}", encode(.object(Json.Object(members: ["key": .array(Json.Array(elements: []))]))))

        // object with objects
        try XCTAssertEqual("{\"key\":{}}", encode(.object(Json.Object(members: ["key": .object(Json.Object(members: [:]))]))))
    }

    func testErrorJson() throws {
        let nsError = NSError(domain: "hello", code: 1, userInfo: [
            "Hello": 123,
            NSLocalizedDescriptionKey: "Hello",
            NSUnderlyingErrorKey: NSError(domain: "my domain", code: 3, userInfo: nil)]
        )
        let jsonFromNSError = Json.NSError(nsError)
        let data = try JSONEncoder().encode(jsonFromNSError)

        let jsonString = String(data: data, encoding: .utf8)!
        print("|err:", jsonString)

        let jsonErrorFromJson = try JSONDecoder().decode(Json.NSError.self, from: data)

        let nsErrorFromJson = jsonErrorFromJson.nsError()

        XCTAssertEqual(nsError, nsErrorFromJson)
    }

    func decode(_ str: String) throws -> Json.Element {
        try TestHelpers.decode(from: str)
    }

    func encode(_ value: Json.Element) throws -> String {
        try TestHelpers.encode(value: value)
    }
}
