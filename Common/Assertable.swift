//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol Assertable {

    func assertArgument(_ assertion: @autoclosure () -> Bool, _ error: Swift.Error) throws
    func assertNil(_ assertion: @autoclosure () -> Any?, _ error: Swift.Error) throws
    func assertNotNil(_ assertion: @autoclosure () -> Any?, _ error: Swift.Error) throws
    func assertTrue(_ assertion: @autoclosure () -> Bool, _ error: Swift.Error) throws
    func assertFalse(_ assertion: @autoclosure () -> Bool, _ error: Swift.Error) throws
    func assertEqual<T>(_ expression1: @autoclosure () -> T,
                        _ expression2: @autoclosure () -> T,
                        _ error: Swift.Error) throws where T: Equatable
    func assertNotEqual<T>(_ expression1: @autoclosure () -> T,
                           _ expression2: @autoclosure () -> T,
                           _ error: Swift.Error) throws where T: Equatable
}

public extension Assertable {

    func assertArgument(_ assertion: @autoclosure () -> Bool, _ error: Swift.Error) throws {
        if !assertion() { throw error }
    }

    func assertNil(_ assertion: @autoclosure () -> Any?, _ error: Swift.Error) throws {
        if assertion() != nil { throw error }
    }

    func assertNotNil(_ assertion: @autoclosure () -> Any?, _ error: Swift.Error) throws {
        if assertion() == nil { throw error }
    }

    func assertTrue(_ assertion: @autoclosure () -> Bool, _ error: Swift.Error) throws {
        if !assertion() { throw error }
    }

    func assertFalse(_ assertion: @autoclosure () -> Bool, _ error: Swift.Error) throws {
        try assertTrue(!assertion(), error)
    }

    func assertEqual<T>(_ expression1: @autoclosure () -> T,
                        _ expression2: @autoclosure () -> T,
                        _ error: Swift.Error) throws where T: Equatable {
        if expression1() != expression2() { throw error }
    }

    func assertNotEqual<T>(_ expression1: @autoclosure () -> T,
                           _ expression2: @autoclosure () -> T,
                           _ error: Swift.Error) throws where T: Equatable {
        if expression1() == expression2() { throw error }
    }

}
