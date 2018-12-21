//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

public typealias dispatch = DispatchQueue

public extension DispatchQueue {

    class var global: DispatchQueue {
        return global()
    }

    class var `default`: DispatchQueue {
        return global
    }

    @discardableResult
    static func async(_ queue: DispatchQueue, closure: @escaping () -> Void) -> DispatchWorkItem {
        return queue.async(closure: closure)
    }

    @discardableResult
    static func sync(_ queue: DispatchQueue, closure: @escaping () -> Void) -> DispatchWorkItem {
        return queue.sync(closure: closure)
    }

    @discardableResult
    func async(closure: @escaping () -> Void) -> DispatchWorkItem {
        return async(item: DispatchWorkItem(block: closure))
    }

    @discardableResult
    func sync(closure: @escaping () -> Void) -> DispatchWorkItem {
        return sync(item: DispatchWorkItem(block: closure))
    }

    @discardableResult
    func async(item: DispatchWorkItem) -> DispatchWorkItem {
        async(execute: item)
        return item
    }

    @discardableResult
    func sync(item: DispatchWorkItem) -> DispatchWorkItem {
        sync(execute: item)
        return item
    }

}

public extension DispatchWorkItem {

    @discardableResult
    func then(_ queue: DispatchQueue, closure: @escaping () -> Void) -> DispatchWorkItem {
        let item = DispatchWorkItem(block: closure)
        notify(queue: queue, execute: item)
        return item
    }

}
