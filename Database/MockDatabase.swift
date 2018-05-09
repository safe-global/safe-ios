//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public class FunctionCallTrace {

    public var log = [String]()

    public init() {}

    public func append(_ str: String) {
        log.append(str)
    }

    public func diff(_ other: [String]) -> String {
        var diffs = [(String, String)]()
        log.enumerated().forEach { offset, logEntry in
            if !(0..<other.count).contains(offset) {
                diffs.append((logEntry, "MISSING"))
            } else if logEntry != other[offset] {
                diffs.append((logEntry, other[offset]))
            }
        }
        if other.count > log.count {
            diffs.append(contentsOf: other[log.count..<other.count].map { ("MISSING", $0) })
        }
        return diffs.map { "trace: \($0)\nother: \($1)" }.joined(separator: "\n---\n")
    }

}

public typealias MockRawResultSet = [[Any?]]

public class MockDatabase: Database {

    public var exists: Bool = true
    public var connections = [Connection]()
    private let trace: FunctionCallTrace
    public var resultSet: MockRawResultSet?

    public init(_ trace: FunctionCallTrace) {
        self.trace = trace
    }

    public func create() throws {}

    public func destroy() throws {}

    public func connection() throws -> Connection {
        trace.append("db.connection()")
        let result = MockConnection(trace, resultSet)
        connections.append(result)
        return result
    }

    public func close(_ connection: Connection) throws {
        trace.append("db.close()")
    }

}

public class MockConnection: Connection {

    public var statements = [MockStatement]()

    private let trace: FunctionCallTrace
    private var resultSet: MockRawResultSet?

    public init(_ trace: FunctionCallTrace, _ resultSet: MockRawResultSet?) {
        self.trace = trace
        self.resultSet = resultSet
    }

    public func prepare(statement: String) throws -> Statement {
        trace.append("conn.prepare(\(statement))")
        let result = MockStatement(trace, resultSet)
        statements.append(result)
        return result
    }

    public func lastErrorMessage() -> String? {
        return nil
    }

}

public class MockStatement: Statement {

    private let trace: FunctionCallTrace
    private var resultSet: MockRawResultSet?

    public init(_ trace: FunctionCallTrace, _ resultSet: MockRawResultSet?) {
        self.trace = trace
        self.resultSet = resultSet
    }

    public func set(_ value: String, at index: Int) throws {
        trace.append("stmt.set(\(value), \(index))")
    }

    public func set(_ value: Int, at index: Int) throws {
        trace.append("stmt.set(\(value), \(index))")
    }

    public func set(_ value: Double, at index: Int) throws {
        trace.append("stmt.set(\(value), \(index))")
    }

    public func setNil(at index: Int) throws {
        trace.append("stmt.setNil(\(index))")
    }

    public func set(_ value: String, forKey key: String) throws {
        trace.append("stmt.set(\(value), \(key))")
    }

    public func set(_ value: Int, forKey key: String) throws {
        trace.append("stmt.set(\(value), \(key))")
    }

    public func set(_ value: Double, forKey key: String) throws {
        trace.append("stmt.set(\(value), \(key))")
    }

    public func setNil(forKey key: String) throws {
        trace.append("stmt.setNil(\(key))")
    }

    public func set(_ value: Data, at index: Int) throws {
        trace.append("stmt.set(\(value), \(index))")
    }

    public func set(_ value: Data, forKey key: String) throws {
        trace.append("stmt.set(\(value), \(index))")
    }

    public func execute() throws -> ResultSet? {
        trace.append("stmt.execute()")
        if let rs = resultSet {
            return MockResultSet(trace, rs)
        }
        return nil
    }

}

public class MockResultSet: ResultSet {

    private let trace: FunctionCallTrace
    private var resultSet: MockRawResultSet
    private var currentRow: Int = -1

    public init(_ trace: FunctionCallTrace, _ resultSet: MockRawResultSet) {
        self.trace = trace
        self.resultSet = resultSet
    }

    public func advanceToNextRow() throws -> Bool {
        trace.append("rs.advanceToNextRow()")
        currentRow += 1
        guard currentRow < resultSet.count && !resultSet.isEmpty else { return false }
        return true
    }

    public func string(at index: Int) -> String? {
        trace.append("rs.string(\(index))")
        return resultSet[currentRow][index] as? String
    }

    public func data(at index: Int) -> Data? {
        trace.append("rs.data(\(index))")
        return resultSet[currentRow][index] as? Data
    }

    public func int(at index: Int) -> Int? {
        trace.append("rs.int(\(index))")
        return resultSet[currentRow][index] as? Int
    }

    public func double(at index: Int) -> Double? {
        trace.append("rs.double(\(index))")
        return resultSet[currentRow][index] as? Double
    }

}
