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
    @IBOutlet private weak var top: NSLayoutConstraint?
    @IBOutlet private weak var textLabel: UILabel?
    @IBOutlet private weak var iconImageView: UIImageView!

    private var currentMessage: Message?

    let offscreen: CGFloat = 1000
    let visible: CGFloat = -20

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
        var icon: IconSource = .none
    }

    enum IconSource: Hashable {
        case image(UIImage)
        case success
        case none
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textLabel?.text = ""
        iconImageView.image = nil
        iconImageView.isHidden = iconImageView.image == nil
        moveSnackbar(to: offscreen)
    }

    static func show(_ message: String, duration: TimeInterval = 4, icon: IconSource = .none) {
        dispatchPrecondition(condition: .onQueue(.main))
        instance?.enqueue(Message(value: message, duration: duration, icon: icon))
        instance?.process()
    }

    private func moveSnackbar(to newValue: CGFloat, completion: @escaping () -> Void = {}) {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 1,
                       options: .curveEaseInOut,
                       animations: { [weak self] in
            self?.top?.constant = newValue
            self?.view.layoutIfNeeded()
        }, completion: { _ in completion() })
    }

    private func enqueue(_ value: Message) {
        messageQueue.append(value)
    }

    // displays the next message in queue and sets the auto-hiding timer
    @objc private func process() {
        dispatchPrecondition(condition: .onQueue(.main))
        guard currentMessage == nil, !messageQueue.isEmpty else { return }
        let message = messageQueue.removeFirst()
        currentMessage = message

        textLabel?.text = message.value
        switch message.icon {
        case .none:
            iconImageView.image = nil

        case .image(let image):
            iconImageView.image = image

        case .success:
            let icon = UIImage(systemName: "checkmark.circle.fill")?.withTintColor(.success, renderingMode: .alwaysOriginal)
            iconImageView.image = icon
        }
        iconImageView.isHidden = iconImageView.image == nil
        
        showAnimated()

        processingTimer?.invalidate()
        processingTimer = Timer.scheduledTimer(withTimeInterval: message.duration,
                                               repeats: false) { [weak self] _ in
            self?.showNextMessage()
        }
    }

    private func showNextMessage() {
        processingTimer?.invalidate()

        // pre-emptively removing duplicate messages that are left in the queue
        while !messageQueue.isEmpty && currentMessage == messageQueue.first {
            messageQueue.removeFirst()
        }

        hideAnimated { [weak self] in
            self?.process()
        }
    }

    private func showAnimated() {
        moveSnackbar(to: visible) // bottomAnchor)
    }

    private func hideAnimated(completion: @escaping () -> Void = {}) {
        moveSnackbar(to: offscreen) { [weak self] in
            self?.currentMessage = nil
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
