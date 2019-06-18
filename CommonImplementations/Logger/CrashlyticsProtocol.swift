//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Protocol for enabling logger tests
public protocol CrashlyticsProtocol {
    func recordError(_ error: Error)
    func setUserIdentifier(_ identifier: String?)
}
