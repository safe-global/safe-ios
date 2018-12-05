//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import Database

public protocol DBSerializable {

    var serializedValue: SQLBindable { get }

}
