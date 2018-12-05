//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Common
import Database

extension BaseID: DBSerializable {

    public var serializedValue: SQLBindable {
        return id
    }

    public convenience init?(serializedString: String?) {
        guard let string = serializedString else { return nil }
        self.init(string)
    }

}
