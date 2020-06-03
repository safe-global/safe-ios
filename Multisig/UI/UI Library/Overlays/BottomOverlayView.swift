//
//  BottomOverlayView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 28.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct BottomOverlayView<Content>: View where Content: View {
    private var isPresented: Binding<Bool>
    private var content: Content

    private let cardBackgroundColor = Color.white
    private let contentHeight: CGFloat = 400

    public init(isPresented: Binding<Bool>,
               @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            SemitransparentBackgroundView()
                .opacity(isPresented.wrappedValue ? 1 : 0)
                .animation(.easeInOut)
                .onTapGesture {
                    self.isPresented.wrappedValue.toggle()
                }

            content
                .background(cardBackgroundColor)
                .opacity(isPresented.wrappedValue ? 1 : 0)
                .offset(y: isPresented.wrappedValue ? 0 : contentHeight)
                .animation(.spring())
        }
    }
}

struct BottomOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        BottomOverlayView(isPresented: .constant(true)) {
            Text("Hello, World!")
        }
    }
}
