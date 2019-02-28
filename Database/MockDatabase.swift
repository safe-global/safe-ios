//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// This class is used to aggregate logs of method calls. Pass instance of this class to a `MockDatabase` object
/// to record function calls, and then you can compare recorded logs in `XCTAssertEqual` with expected array
/// of logs. It is handy to use `FunctionCallTrace.diff(...)` method as message parameter for the assertion to
/// see where the logs differ.
public class FunctionCallTrace {

    /// Log of method calls
    public var log = [String]()

    /// Creates new trace
    public init() {}

    /// Appends a string to log.
    ///
    /// - Parameter str: any string to log, usually a function call description
    public func append(_ str: String) {
        log.append(str)
    }

    /// Computes difference between `other` log and this trace's `log` and returns resulting string
    /// that shows whether some lines are missing in whichever logs.
    ///
    /// - Parameter other: Another log to compare with
    /// - Returns: String description of logs difference, or empty string if logs are equal.
    public func diff(_ other: [String]) -> String {
        var diffs = [(String, String)]()
        log.enumerated().forEach { offset, logEntry in
            if other.indices ~= offset {
                diffs.append((logEntry, other[offset]))
            } else if logEntry != other[offset] {
                diffs.append((logEntry, "MISSING"))
            }
        }
        if other.count > log.count {
            diffs.append(contentsOf: other[log.count..<other.count].map { ("MISSING", $0) })
        }
        return diffs.map { "trace: \($0)\nother: \($1)" }.joined(separator: "\n---\n")
    }

}

/// An array of optional Any values, used as a source of `MockResultSet` return values.
public typealias MockRawResultSet = [[Any?]]

/// Mock database for use in tests or other mocks. To mock results of SQL queries with arbitrary values,
/// set `resultSet` variable with a `MockRawResultSet` value (array of arrays), and it will be used down the chain
/// in `MockConnection`s that will then generate `MockStatement`s, that in turn will create `MockResultSet` that will
/// use the `resultSet` value.
public class MockDatabase: Database {

    public var exists: Bool = true

    /// Holds all statements created with `connection()` method.
    public var connections = [Connection]()
    private let trace: FunctionCallTrace
    public var resultSet: MockRawResultSet?

    public init(_ trace: FunctionCallTrace) {
        self.trace = trace
    }

    public func create() throws {}

    public func destroy() throws {}

    /// Appends "db.connection()" to the trace. Creates and returns new `MockConnection`. Created connection
    /// added to `connections` array.
    public func connection() throws -> Connection {
        trace.append("db.connection()")
        let result = MockConnection(trace, resultSet)
        connections.append(result)
        return result
    }

    /// Appends "db.close()" to the trace.
    public func close(_ connection: Connection) throws {
        trace.append("db.close()")
    }

}

/// Mock implementation of a `Connection` protocol that logs function calls to `FunctionCallTrace`.
/// This class created automatically by `MockDatabase.connection()` method.
public class MockConnection: Connection {

    /// Holds all statements created with `prepare(...)` method.
    public var statements = [MockStatement]()

    private let trace: FunctionCallTrace
    private var resultSet: MockRawResultSet?

    public init(_ trace: FunctionCallTrace, _ resultSet: MockRawResultSet?) {
        self.trace = trace
        self.resultSet = resultSet
    }

    /// Appends "conn.prepare(statement)" with value of the `statement` argument. Creates and returns new
    /// `MockStatement`, also appending it to the `statements` array.
    public func prepare(statement: String) throws -> Statement {
        trace.append("conn.prepare(\(statement))")
        let result = MockStatement(trace, resultSet)
        statements.append(result)
        return result
    }

    /// Returns nil.
    public func lastErrorMessage() -> String? {
        return nil
    }

}

/// Mock implementation of a `Statement` protocol that logs function calls to `FunctionCallTrace`.
/// This class created automatically by `MockConnection.prepare(...)` method.
public class MockStatement: Statement {

    private let trace: FunctionCallTrace
    private var resultSet: MockRawResultSet?

    /// Creates new statement with trace and array of rows to pass to result set returned from `execute()` method.
    ///
    /// - Parameters:
    ///   - trace: trace to write method call logs to.
    ///   - resultSet: values to use in `MockResultSet`
    public init(_ trace: FunctionCallTrace, _ resultSet: MockRawResultSet?) {
        self.trace = trace
        self.resultSet = resultSet
    }

    /// Appends "stmt.set(value, index)" to trace with actual values of `value` and `index` arguments
    public func set(_ value: String, at index: Int) throws {
        trace.append("stmt.set(\(value), \(index))")
    }

    /// Appends "stmt.set(value, index)" to trace with actual values of `value` and `index` arguments
    public func set(_ value: Int, at index: Int) throws {
        trace.append("stmt.set(\(value), \(index))")
    }

    /// Appends "stmt.set(value, index)" to trace with actual values of `value` and `index` arguments
    public func set(_ value: Double, at index: Int) throws {
        trace.append("stmt.set(\(value), \(index))")
    }

    /// Appends "stmt.set(value, index)" to trace with actual values of `value` and `index` arguments
    public func set(_ value: Data, at index: Int) throws {
        trace.append("stmt.set(\(value), \(index))")
    }

    /// Appends "stmt.setNil(index)" to trace with actual value of `index` argument
    public func setNil(at index: Int) throws {
        trace.append("stmt.setNil(\(index))")
    }

    /// Appends "stmt.set(value, key)" to trace with actual values of `value` and `key` arguments
    public func set(_ value: String, forKey key: String) throws {
        trace.append("stmt.set(\(value), \(key))")
    }

    /// Appends "stmt.set(value, key)" to trace with actual values of `value` and `key` arguments
    public func set(_ value: Int, forKey key: String) throws {
        trace.append("stmt.set(\(value), \(key))")
    }

    /// Appends "stmt.set(value, key)" to trace with actual values of `value` and `key` arguments
    public func set(_ value: Double, forKey key: String) throws {
        trace.append("stmt.set(\(value), \(key))")
    }

    /// Appends "stmt.set(value, key)" to trace with actual values of `value` and `key` arguments
    public func set(_ value: Data, forKey key: String) throws {
        trace.append("stmt.set(\(value), \(index))")
    }

    /// Appends "stmt.setNil(key)" to trace with actual value of the `key` argument
    public func setNil(forKey key: String) throws {
        trace.append("stmt.setNil(\(key))")
    }

    /// Appends "stmt.execute()" to the trace. Returns new `MockResultSet` if the `resultSet` parameter not nil.
    ///
    /// - Returns: `MockResultSet`
    public func execute() throws -> ResultSet? {
        trace.append("stmt.execute()")
        if let rs = resultSet {
            return MockResultSet(trace, rs)
        }
        return nil
    }

}

/// Mock implementation of a ResultSet that is based on a value passed in from `MockDatabase.resultSet`.
public class MockResultSet: ResultSet {

    private let trace: FunctionCallTrace
    private var resultSet: MockRawResultSet
    private var currentRow: Int = -1

    /// Creates new `MockResultSet` with trace and array of rows to return from other calls
    ///
    /// - Parameters:
    ///   - trace: trace object
    ///   - resultSet: resulting rows to represent by this mock result set.
    public init(_ trace: FunctionCallTrace, _ resultSet: MockRawResultSet) {
        self.trace = trace
        self.resultSet = resultSet
    }

    /// Appends "rs.advanceToNextRow()" to trace.
    /// Moves current row index forward, so that other methods return items from the next result row.
    ///
    /// - Returns: True if no more rows left to traverse, false if more rows available.
    public func advanceToNextRow() throws -> Bool {
        trace.append("rs.advanceToNextRow()")
        currentRow += 1
        guard currentRow < resultSet.count && !resultSet.isEmpty else { return false }
        return true
    }

    /// Appends "rs.string(index)" to the trace with actual value of the `index` argument.
    /// Returns value at current row at the specified index optionally unwrapped as a String.
    ///
    /// - Parameter index: index of an item in the current row
    /// - Returns: value unwrapped as a String, or nil if unwrapping fails.
    public func string(at index: Int) -> String? {
        trace.append("rs.string(\(index))")
        return resultSet[currentRow][index] as? String
    }

    /// Appends "rs.data(index)" to the trace with actual value of the `index` argument.
    /// Returns value at current row at the specified index optionally unwrapped as a Data.
    ///
    /// - Parameter index: index of an item in the current row
    /// - Returns: value unwrapped as a Data, or nil if unwrapping fails.
    public func data(at index: Int) -> Data? {
        trace.append("rs.data(\(index))")
        return resultSet[currentRow][index] as? Data
    }

    /// Appends "rs.int(index)" to the trace with actual value of the `index` argument.
    /// Returns value at current row at the specified index optionally unwrapped as an Int.
    ///
    /// - Parameter index: index of an item in the current row
    /// - Returns: value unwrapped as an Int, or nil if unwrapping fails.
    public func int(at index: Int) -> Int? {
        trace.append("rs.int(\(index))")
        return resultSet[currentRow][index] as? Int
    }

    /// Appends "rs.double(index)" to the trace with actual value of the `index` argument.
    /// Returns value at current row at the specified index optionally unwrapped as a Double.
    ///
    /// - Parameter index: index of an item in the current row
    /// - Returns: value unwrapped as a Double, or nil if unwrapping fails.
    public func double(at index: Int) -> Double? {
        trace.append("rs.double(\(index))")
        return resultSet[currentRow][index] as? Double
    }

    public func string(column: String) -> String? {
        return nil
    }

    public func int(column: String) -> Int? {
        return nil
    }

    public func double(column: String) -> Double? {
        return nil
    }

    public func data(column: String) -> Data? {
        return nil
    }

}
