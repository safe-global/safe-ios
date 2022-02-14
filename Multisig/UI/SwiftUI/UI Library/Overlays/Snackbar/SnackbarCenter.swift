//
//  SnackbarCenter.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.07.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

class SnackbarCenter: ObservableObject {

    @Published
    var isPresented: Bool = false

    @Published
    var bottomEdgeSpacing: CGFloat = ScreenMetrics.aboveBottomEdge

    @Published
    private(set) var snackbarMessge: String?

    private var presentedMessage: Message?
    private var messageQueue: [Message] = []
    private var working = false
    private var pipeline = PassthroughSubject<Void, Never>()
    private var subscribers = Set<AnyCancellable>()
    private let displayDuration: TimeInterval = 4
    private var bottomPaddingStack: [CGFloat] = []

    private struct Message: Hashable, CustomStringConvertible {
        var id = UUID()
        var content: String
        var duration: TimeInterval

        var description: String {
            id.uuidString + " " + content
        }
    }

    init() {
        recreatePipeline()
    }

    func setBottomPadding(_ value: CGFloat = ScreenMetrics.aboveBottomEdge) {
        bottomPaddingStack.append(value)
        updateBottomEdgeSpacing()
    }

    func resetBottomPadding() {
        if !bottomPaddingStack.isEmpty {
            bottomPaddingStack.removeLast()
        }
        updateBottomEdgeSpacing()
    }

    private func updateBottomEdgeSpacing() {
        withAnimation {
            bottomEdgeSpacing = bottomPaddingStack.last ?? ScreenMetrics.aboveBottomEdge
        }
    }

    func show(error: DetailedLocalizedError) {
        show(message: error.localizedDescription)
        if error.loggable {
            LogService.shared.error(error.localizedDescription, error: error)
        }
    }

    func show(message content: String, duration: TimeInterval? = nil, icon: SnackbarViewController.IconSource = .none) {
        // The average adult reading speed is 200 to 250 words a minute, which is around 4 words a second
        // It also takes some time to switch context to notification message, so we will add 1 second for that
        let words =  content.split { !$0.isLetter }.count
        let estimatedReadingTime = TimeInterval(words) / 4 + 2
        let reasonableDuration = max(displayDuration, estimatedReadingTime)
        SnackbarViewController.show(content, duration: duration ?? reasonableDuration, icon: icon)
    }

    func hide() {
        if let message = presentedMessage {
            hide(message)
            recreatePipeline()
            triggerMessagePresentation()
        }
    }

    private func triggerMessagePresentation() {
        pipeline.send()
    }

    private func recreatePipeline() {
        // cancels all existing subscribers (on deinit)
        subscribers = []
        working = false

        // Pipeline overview:
        // dequeues the topmost message
        // presents it
        // hides it after delay (if message is still presented)
        // restarts this cycle if more messages pending

        pipeline
            // prevent starting pipeline if it is already displaying message
            .filter { !self.working }

            // dequeue
            .compactMap { _ -> Message? in
                if self.messageQueue.isEmpty {
                    return nil
                }
                self.working = true
                let message = self.messageQueue.removeFirst()
                return message
            }

            // in case of multiple messages, this gives time for the
            // hiding animation of the previous message to complete
            .delay(for: .seconds(0.1), scheduler: RunLoop.main)

            .map { message -> Message in
                self.present(message)
                return message
            }
            .flatMap { message in
                Just(message)
                    .delay(for: .seconds(message.duration), scheduler: RunLoop.main)
            }

            // check because user could hide the current message via `hide()`
            .filter { $0 == self.presentedMessage }

            .map { message -> Message in
                self.hide(message)
                return message
            }

            // restart the cycle if needed
            .sink { [weak self] message in
                guard let `self` = self else { return }
                self.working = false

                // Removing duplicate messages from the queue in case
                // multiple similar errors appeared (multiple requests
                // failed with "Internet connection failed" error)
                while self.messageQueue.first?.content == message.content {
                    self.messageQueue.removeFirst()
                }

                if !self.messageQueue.isEmpty {
                    self.pipeline.send()
                }
            }
            .store(in: &subscribers)
    }

    private func present(_ message: Message) {
        presentedMessage = message
        snackbarMessge = message.content
        isPresented = true
    }

    private func hide(_ message: Message) {
        guard presentedMessage == message else { return }
        snackbarMessge = nil
        isPresented = false
        presentedMessage = nil
    }

}
