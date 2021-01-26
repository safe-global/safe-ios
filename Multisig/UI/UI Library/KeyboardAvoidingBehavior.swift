//
//  KeyboardAvoidingBehavior.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 21.01.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class KeyboardAvoidingBehavior {
    private weak var scrollView: UIScrollView!
    private let notificationCenter: NotificationCenter

    /// Set this variable to reference active text field when a text field gets focus
    var activeTextField: UITextField? {
        get { return activeResponder as? UITextField }
        set { activeResponder = newValue }
    }
    var activeTextView: UITextView? {
        get { return activeResponder as? UITextView }
        set { activeResponder = newValue }
    }

    var activeResponder: UIView? {
        didSet {
            guard let activeResponder = activeResponder else { return }
            activate(activeResponder)
        }
    }

    init(scrollView: UIScrollView, notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.scrollView = scrollView
        self.notificationCenter = notificationCenter
        let touchRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapScrollView))
        scrollView.gestureRecognizers?.forEach { touchRecognizer.require(toFail: $0) }
        scrollView.addGestureRecognizer(touchRecognizer)
    }

    func start() {
        notificationCenter.addObserver(self,
                                       selector: #selector(didShowKeyboard(_:)),
                                       name: UIResponder.keyboardDidShowNotification,
                                       object: nil)
        notificationCenter.addObserver(self,
                                       selector: #selector(didHideKeyboard(_:)),
                                       name: UIResponder.keyboardWillHideNotification,
                                       object: nil)

    }

    func stop() {
        notificationCenter.removeObserver(self, name: nil, object: nil)
    }

    @objc func didTapScrollView() {
        if let responder = activeResponder {
            deactivate(responder)
        }
    }

    @objc func didShowKeyboard(_ notification: NSNotification) {
        guard let view = scrollView.superview else { return }
        guard let screenValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        let keyboardScreen = screenValue.cgRectValue
        let keyboardFrame = view.convert(keyboardScreen, from: UIScreen.main.coordinateSpace)
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.scrollIndicatorInsets = scrollView.contentInset
        var rect = view.bounds
        rect.size.height -= keyboardFrame.height
        if let frame = responderFrame(in: view), !rect.contains(frame) {
            var animated = true
            if let isSuppressing = notification.userInfo?["suppress_animation"] as? Bool {
                animated = !isSuppressing
            }
            // Otherwise, the scrolling interferes with default textfield behavior provided by iOS.
            DispatchQueue.main.async { [weak self] in
                self?.scrollView.scrollRectToVisible(frame, animated: animated)
            }
        }
    }

    private func responderFrame(in parent: UIView) -> CGRect? {
        guard let field = activeResponder else { return nil }
        let frame = parent.convert(field.bounds, from: field)
        return frame.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: -20, right: 0))
    }

    @objc func didHideKeyboard(_ notification: NSNotification) {
        scrollView.contentInset.bottom = 0
        scrollView.scrollIndicatorInsets = scrollView.contentInset
    }

    private func activate(_ responder: UIView) {
        responder.becomeFirstResponder()
    }

    private func deactivate(_ responder: UIView) {
        responder.resignFirstResponder()
    }
}
