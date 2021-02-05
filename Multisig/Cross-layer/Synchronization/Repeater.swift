//
//  Repeater.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 05.02.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import Foundation

/// Repeats a closure until stopped explicitly, delaying every repetition with a configured `delay` time interval.
class Repeater {
    private let main: (Repeater) -> Void
    private let delay: TimeInterval
    private var state: State = .stopped

    var isStopped: Bool { return state == .stopped }
    var isRunning: Bool { return state == .running }

    private enum State {
        case stopped
        case running
        case waiting
    }

    init (delay: TimeInterval, _ main: @escaping (Repeater) -> Void) {
        self.main = main
        self.delay = delay
    }

    func start() {
        dispatchPrecondition(condition: .notOnQueue(.main))

        guard isStopped else { return }
        repeat {
            state = .running
            main(self)
            if isStopped { return }
            state = .waiting
            sleep(UInt32(delay * 1_000_000))
        } while !isStopped
    }

    func stop() {
        state = .stopped
    }
}
