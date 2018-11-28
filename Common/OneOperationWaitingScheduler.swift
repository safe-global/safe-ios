//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Allows to schedule operations that will be executed not more often than once in "interval" seconds.
/// It allows to have only one operation in a queue to execute.
public final class OneOperationWaitingScheduler {

    let queue: OperationQueue
    let interval: TimeInterval
    var lastExecutionDate: Date?

    public init(interval: TimeInterval) {
        self.interval = interval
        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
    }

    public func schedule(_ block: (() -> Void)?) {
        guard queue.operations.isEmpty else { return }
        queue.addOperation { [weak self] in
            guard let `self` = self else { return }
            var delay: TimeInterval = 0
            if let lastExecutionDate = self.lastExecutionDate {
                delay = max(delay, self.interval - Date().timeIntervalSince(lastExecutionDate))
            }
            Timer.wait(delay)
            block?()
            self.lastExecutionDate = Date()
        }
    }

}
