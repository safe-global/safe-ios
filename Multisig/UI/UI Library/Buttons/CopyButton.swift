//
//  CopyButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

fileprivate var timers: [UUID: Timer] = [:]

struct CopyButton<Content: View>: View {

    var value: String?
    var content: Content

    @State private var wasCopied: Bool = false
    @State private var timerID: UUID?
    private let tooltipDuration: TimeInterval = 2
    private let tooltipText = "Copied to clipboard"
    private let tooltipHeight: CGFloat = 48

    init(_ value: String? = nil, @ViewBuilder _ content: () -> Content) {
        self.value = value
        self.content = content()
    }

    var body: some View {
        ZStack {
            copyButton
                .background(wasCopied ? Color.gnoSystemSelection : nil)

//            Tooltip(tooltipText)
//                .offset(y: -tooltipHeight)
//                .opacity(wasCopied ? 1 : 0)
//                .zIndex(10_000)

            Tooltip(tooltipText)
                .opacity(wasCopied ? 1 : 0)
        }
    }

    var copyButton: some View {
        Button(action: copyToPasteboard) {
            content
        }
        .buttonStyle(BorderlessButtonStyle())
    }

    func copyToPasteboard() {
        Pasteboard.string = value

        // Alternative: snackbar
//        App.shared.snackbar.show(message: "Copied to clipboard")

        if let existing = timerID, let timer = timers[existing] {
            timer.invalidate()
            timers.removeValue(forKey: existing)
        }

        withAnimation {
            wasCopied = true
        }

        let id = UUID()
        timerID = id
        let timer = Timer.scheduledTimer(withTimeInterval: tooltipDuration, repeats: false) { _ in
            withAnimation {
                self.wasCopied = false
            }
            timers.removeValue(forKey: id)
        }
        timers[id] = timer
    }
}

extension CopyButton {
    init(_ address: Address, @ViewBuilder _ content: () -> Content) {
        self.init(address.checksummed, content)
    }
}

struct CopyButton_Previews: PreviewProvider {
    static var previews: some View {
        CopyButton("This is copied text 📜") {
            Text("Copy")
        }
    }
}
