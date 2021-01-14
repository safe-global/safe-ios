//
//  KeyboardAdaptive.swift
//  KeyboardAvoidanceSwiftUI
//
//  Created by Vadim Bulavin on 3/27/20.
//  Copyright © 2020 Vadim Bulavin. All rights reserved.
//

import SwiftUI
import Combine
import UIKit

// Adapted from (thanks to)
// https://www.vadimbulavin.com/how-to-move-swiftui-view-when-keyboard-covers-text-field/
struct KeyboardAdaptive: ViewModifier {

    let responderPadding: CGFloat

    @State
    private var bottomPadding: CGFloat = 0

    @State
    private var offsetY: CGFloat = 0

    func body(content: Content) -> some View {
        ScrollView {
            content
                .padding(.bottom, bottomPadding)
                .offset(y: offsetY)
        }
        .onReceive(Publishers.willShowKeyboard) { keyboardFrame in
            var visibleRect = UIScreen.main.bounds
            visibleRect.size.height -= keyboardFrame.height

            let adjustedResponderFrame = UIResponder.currentFirstResponder?
                .globalFrame?.insetBy(dx: -self.responderPadding, dy: -self.responderPadding)

            if let responderFrame = adjustedResponderFrame, !visibleRect.contains(responderFrame) {
                withAnimation {
                    self.bottomPadding = keyboardFrame.height
                    let change = abs(keyboardFrame.minY - responderFrame.maxY)
                    self.offsetY = -change
                }
            }
            App.shared.snackbar.setBottomPadding(ScreenMetrics.aboveKeyboard(keyboardFrame))
        }
        .onReceive(Publishers.willHideKeyboard) { _ in
            withAnimation {
                self.bottomPadding = 0
                self.offsetY = 0
            }
            App.shared.snackbar.resetBottomPadding()
        }
        .onTapGesture {
            UIResponder.resignCurrentFirstResponder()
        }
    }
}

extension View {
    func keyboardAdaptive(padding: CGFloat = Spacing.extraExtraLarge) -> some View {
        modifier(KeyboardAdaptive(responderPadding: padding))
    }
}

extension Publishers {

    static let willShowKeyboard = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
        .map { $0.keyboardFrame }
        .eraseToAnyPublisher()

    static let willHideKeyboard = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
        .map { $0.keyboardFrame }
        .eraseToAnyPublisher()
}

extension Notification {
    var keyboardFrame: CGRect {
        (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect) ?? .zero
    }
}

// From https://stackoverflow.com/a/14135456/6870041
extension UIResponder {
    static var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }

    // from https://stackoverflow.com/questions/1823317/get-the-current-first-responder-without-using-a-private-api
    static func resignCurrentFirstResponder() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private static weak var _currentFirstResponder: UIResponder?

    @objc private func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }

    var globalFrame: CGRect? {
        guard let view = self as? UIView else { return nil }
        return view.superview?.convert(view.frame, to: nil)
    }
}
