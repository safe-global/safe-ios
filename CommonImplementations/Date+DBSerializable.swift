//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Database

extension Date: DBSerializable {

    public var serializedValue: SQLBindable {
        return timeIntervalSinceReferenceDate
    }

    public init?(serializedValue: String?) {
        guard let string = serializedValue, let time = TimeInterval(string) else { return nil }
        self.init(timeIntervalSinceReferenceDate: time)
    }

}
