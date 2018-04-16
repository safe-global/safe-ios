//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public protocol Assertable {

    func assertArgument(_ assertion: @autoclosure () -> Bool, _ error: Swift.Error) throws

}

public extension Assertable {

    func assertArgument(_ assertion: @autoclosure () -> Bool, _ error: Swift.Error) throws {
        if !assertion() { throw error }
    }

}
