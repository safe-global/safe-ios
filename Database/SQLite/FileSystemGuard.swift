//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

open class FileSystemGuard {

    private let queue: DispatchQueue
    private var hasAccess: Bool = true
    private var semaphores: [DispatchSemaphore] = []

    public init() {
        queue = DispatchQueue(label: "FileSystemGuardLockQueue",
                              qos: .userInitiated,
                              attributes: []) // serial by default
        subscribeForLockingEvents()
    }

    private func subscribeForLockingEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didUnlock),
            name: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didLock),
            name: UIApplication.protectedDataWillBecomeUnavailableNotification,
            object: nil)
    }

    open func addUnlockSemaphore(_ semaphore: DispatchSemaphore) {
        queue.async { [unowned self] in
            if !self.checkSemaphore(semaphore) {
                self.semaphores.append(semaphore)
            }
        }
    }

    private func checkSemaphore(_ sema: DispatchSemaphore) -> Bool {
        if hasAccess {
            sema.signal()
        }
        return hasAccess
    }

    @objc open func didUnlock() {
        queue.async { [unowned self] in
            self.hasAccess = true
            while !self.semaphores.isEmpty {
                _ = self.checkSemaphore(self.semaphores.removeFirst())
            }
        }
    }

    @objc open func didLock() {
        queue.async { [unowned self] in
            self.hasAccess = false
        }
    }

}
