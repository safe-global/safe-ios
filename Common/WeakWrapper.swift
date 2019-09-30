//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public class WeakWrapper {

    public weak var ref: AnyObject?

    public init (_ ref: AnyObject?) {
        self.ref = ref
    }

}

public class TypedWeakWrapper<T: AnyObject> {

    public weak var ref: T?

    public init (_ ref: T?) {
        self.ref = ref
    }

}
