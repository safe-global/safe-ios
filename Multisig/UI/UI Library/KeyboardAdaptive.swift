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
    @State private var bottomPadding: CGFloat = 0
    @State private var offsetY: CGFloat = 0

    func body(content: Content) -> some View {
        ScrollView {
            content
                .padding(.bottom, bottomPadding)
                .offset(y: offsetY)
        }
        .onReceive(Publishers.keyboardHeight) { keyboardHeight in
            withAnimation {
                self.bottomPadding = keyboardHeight
                let focusedTextInputBottom = UIResponder.currentFirstResponder?.globalFrame?.maxY ?? 0
                self.offsetY = keyboardHeight > 0 ? (keyboardHeight - focusedTextInputBottom) : 0
            }
        }
        .onTapGesture {
            UIResponder.resignCurrentFirstResponder()
        }
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        modifier(KeyboardAdaptive())
    }
}

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { $0.keyboardHeight }

        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
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
