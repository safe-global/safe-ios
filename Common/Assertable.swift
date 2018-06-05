//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// `Assertable` protocol provides utilities to assert method arguments or class invariants and throw error on assertion
/// failure.
public protocol Assertable {

    /// Asserts that condition is true, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - assertion: Condition to assert
    ///   - error: Error thrown if condition evaluates to false
    /// - Throws: Throws `error` when condition does not hold
    func assertArgument(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws

    /// Asserts that `assertion` is nil, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - assertion: Argument or expression to check
    ///   - error: Error thrown if expression is not nil
    /// - Throws: Throws `error` if assertion fails.
    func assertNil(_ assertion: @autoclosure () throws -> Any?, _ error: Swift.Error) throws

    /// Asserts that `assertion` is not nil, otherwise throws `error`
    ///
    /// - Parameters:
    ///   - assertion: Argument or expression to check
    ///   - error: Eror thrown if expression is nil
    /// - Throws: `error` if assertion fails.
    func assertNotNil(_ assertion: @autoclosure () throws -> Any?, _ error: Swift.Error) throws

    /// Asserts that `assertion` is true, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - assertion: Argument or expression to be check if true
    ///   - error: Error thrown if expression is false
    /// - Throws: `error` if assertion fails.
    func assertTrue(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws

    /// Asserts that `assertion` is false, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - assertion: Argument or expression to check
    ///   - error: Error thrown if expression is true.
    /// - Throws: `error` if assertion fails
    func assertFalse(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws

    /// Asserts that two arguments are equal, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - expression1: First expression to compare.
    ///   - expression2: Second expression to compare.
    ///   - error: Error thrown if expression1 is not equal to expression2.
    /// - Throws: `error` if assertion fails.
    func assertEqual<T>(_ expression1: @autoclosure () throws -> T,
                        _ expression2: @autoclosure () throws -> T,
                        _ error: Swift.Error) throws where T: Equatable

    /// Asserts that two arguments are not equal, otherwise throws `error`.
    ///
    /// - Parameters:
    ///   - expression1: First expression to compare.
    ///   - expression2: Second expression to compare.
    ///   - error: Error thrown if expression1 is equal to expression2.
    /// - Throws: `error` if assertion fails.
    func assertNotEqual<T>(_ expression1: @autoclosure () throws -> T,
                           _ expression2: @autoclosure () throws -> T,
                           _ error: Swift.Error) throws where T: Equatable
}

public extension Assertable {

    func assertArgument(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws {
        if try !assertion() { throw error }
    }

    func assertNil(_ assertion: @autoclosure () throws -> Any?, _ error: Swift.Error) throws {
        if try assertion() != nil { throw error }
    }

    func assertNotNil(_ assertion: @autoclosure () throws -> Any?, _ error: Swift.Error) throws {
        if try assertion() == nil { throw error }
    }

    func assertTrue(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws {
        if try !assertion() { throw error }
    }

    func assertFalse(_ assertion: @autoclosure () throws -> Bool, _ error: Swift.Error) throws {
        try assertTrue(!assertion(), error)
    }

    func assertEqual<T>(_ expression1: @autoclosure () throws -> T,
                        _ expression2: @autoclosure () throws -> T,
                        _ error: Swift.Error) throws where T: Equatable {
        if try expression1() != expression2() { throw error }
    }

    func assertNotEqual<T>(_ expression1: @autoclosure () throws -> T,
                           _ expression2: @autoclosure () throws -> T,
                           _ error: Swift.Error) throws where T: Equatable {
        if try expression1() == expression2() { throw error }
    }

}
