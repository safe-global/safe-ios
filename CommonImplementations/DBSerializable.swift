//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Database
import Common

public protocol DBSerializable {

    var serializedValue: SQLBindable { get }

}

extension BaseID: DBSerializable {

    public var serializedValue: SQLBindable {
        return id
    }

    public convenience init?(serializedString: String?) {
        guard let string = serializedString else { return nil }
        self.init(string)
    }

}

extension String: DBSerializable {

    public var serializedValue: SQLBindable {
        return self
    }

}

extension Bool: DBSerializable {

    public var serializedValue: SQLBindable {
        return self
    }

}

extension Int: DBSerializable {

    public var serializedValue: SQLBindable {
        return self
    }

}

extension Double: DBSerializable {

    public var serializedValue: SQLBindable {
        return self
    }

}

extension Date: DBSerializable {

    public var serializedValue: SQLBindable {
        return timeIntervalSinceReferenceDate
    }

    public init?(serializedValue: String?) {
        guard let string = serializedValue, let time = TimeInterval(string) else { return nil }
        self.init(timeIntervalSinceReferenceDate: time)
    }

}
