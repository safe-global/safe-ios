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
    static func asynchronous(_ queue: DispatchQueue, closure: @escaping () -> Void) -> DispatchWorkItem {
        return queue.asynchronous(closure: closure)
    }

    @discardableResult
    static func synchronous(_ queue: DispatchQueue, closure: @escaping () -> Void) -> DispatchWorkItem {
        return queue.synchronous(closure: closure)
    }

    @discardableResult
    func asynchronous(closure: @escaping () -> Void) -> DispatchWorkItem {
        return asynchronous(item: DispatchWorkItem(block: closure))
    }

    @discardableResult
    func synchronous(closure: @escaping () -> Void) -> DispatchWorkItem {
        return synchronous(item: DispatchWorkItem(block: closure))
    }

    @discardableResult
    func asynchronous(item: DispatchWorkItem) -> DispatchWorkItem {
        async(execute: item)
        return item
    }

    @discardableResult
    func synchronous(item: DispatchWorkItem) -> DispatchWorkItem {
        sync(execute: item)
        return item
    }

    static func onMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
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
