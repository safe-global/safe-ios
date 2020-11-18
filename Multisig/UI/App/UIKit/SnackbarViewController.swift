//
//  SnackbarViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

// A singleton controller to show snackbar messages.
class SnackbarViewController: UIViewController {

    // singleton instance, needs to be set from outside
    static weak var instance: SnackbarViewController?
    var notificationCenter = NotificationCenter.default

    // bottom constraint to animate showing/hiding of the message
    @IBOutlet private weak var bottom: NSLayoutConstraint!
    @IBOutlet private weak var textLabel: UILabel!

    // storage of the bottom anchor for when the message is visible
    private var bottomAnchor: CGFloat = ScreenMetrics.aboveTabBar

    private var currentMessage: Message?

    // FIFO queue of messages
    private var messageQueue = [Message]()

    // timer to hide message automatically
    private var processingTimer: Timer?

    private var isShowingMessage: Bool {
        currentMessage != nil
    }

    // Content to show on screen
    private struct Message: Hashable {
        var value: String
        var duration: TimeInterval = 4
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel.text = ""
        moveSnackbarBottom(to: ScreenMetrics.offscreen)
        // to prevent keyboard overlaying the snackbar message
        notificationCenter.addObserver(self,
                                       selector: #selector(willShowKeyboard(_:)),
                                       name: UIWindow.keyboardWillShowNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(willHideKeyboard(_:)),
                                       name: UIWindow.keyboardWillHideNotification,
                                       object: nil)
    }

    static func show(_ message: String, duration: TimeInterval = 4) {
        instance?.enqueue(Message(value: message, duration: duration))
        instance?.process()
    }

    @objc private func willShowKeyboard(_ notification: Notification) {
        bottomAnchor = ScreenMetrics.aboveKeyboard(notification.keyboardFrame)

        if isShowingMessage {
            moveSnackbarBottom(to: bottomAnchor)
        }
    }

    @objc private func willHideKeyboard(_ notification: Notification) {
        bottomAnchor = ScreenMetrics.aboveTabBar

        if isShowingMessage {
            moveSnackbarBottom(to: bottomAnchor)
        }
    }

    private func moveSnackbarBottom(to newValue: CGFloat, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 1,
                       options: .curveEaseInOut,
                       animations: { [unowned self] in
            self.bottom.constant = newValue
            self.view.layoutIfNeeded()
        }, completion: { _ in completion() })
    }

    private func enqueue(_ value: Message) {
        messageQueue.append(value)
    }

    // displays the next message in queue and sets the auto-hiding timer
    @objc private func process() {
        guard currentMessage == nil, !messageQueue.isEmpty else { return }
        currentMessage = messageQueue.removeFirst()
        textLabel.text = currentMessage?.value
        showAnimated()
        processingTimer = Timer.scheduledTimer(withTimeInterval: currentMessage!.duration,
                                               repeats: false) { [weak self] _ in
            self?.showNextMessage()
        }
    }

    private func showNextMessage() {
        // skip showing if last message is duplicate of the next message
        while currentMessage == messageQueue.first {
            messageQueue.removeFirst()
        }
        hideAnimated { [weak self] in
            self?.process()
        }
    }

    private func showAnimated() {
        moveSnackbarBottom(to: bottomAnchor)
    }

    private func hideAnimated(completion: @escaping () -> Void = {}) {
        processingTimer?.invalidate()
        processingTimer = nil

        moveSnackbarBottom(to: ScreenMetrics.offscreen) { [unowned self] in
            self.currentMessage = nil
            completion()
        }
    }

    @IBAction private func didTapMessage(_ sender: Any) {
        showNextMessage()
    }
}


// Many thanks to this stackoverflow: https://stackoverflow.com/a/41851742
// This makes the SnackbarVC's view to pass the touches to the underlying
// views.
class TouchthroughView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        subviews.contains {
            !$0.isHidden &&
                $0.isUserInteractionEnabled &&
                $0.point(inside: convert(point, to: $0), with: event)
        }
    }
}
