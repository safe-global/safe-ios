//
//  PopupView.swift
//  Multisig
//
//  Created by Moaaz on 4/30/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct PopupView<Content>: View where Content: View {

    private var isPresented: Binding<Bool>
    private var content: Content

    private let backgroundOpacity: Double = 0.2
    private let horizontalContentInset: CGFloat = 24

    private let onAppearCardScale: CGFloat = 0.95
    private let cardYOffsetFromMiddle: CGFloat = -90

    private let verticalContentInset: CGFloat = 16
    private let screenEdgePadding: CGFloat = 16

    private let cardCornerRadius: CGFloat = 10

    private let cardBackgroundColor = Color.white

    @inlinable public init(isPresented: Binding<Bool>,
                           @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack(alignment: .center) {
            if isPresented.wrappedValue {
                backgroundView
                    .transition(AnyTransition.opacity.animation(.easeInOut))
                cardView
                    .transition(
                        AnyTransition
                            .opacity
                            .combined(with: .scale(scale: onAppearCardScale))
                            .animation(.spring())
                    )
            } else {
                EmptyView()
            }
        }
        .onTapGesture {
            // using withAnimation actually animates the transitioning
            withAnimation {
                self.isPresented.wrappedValue = false
            }
        }
    }

    var backgroundView: some View {
        Rectangle()
            .background(Color.black)
            .edgesIgnoringSafeArea(.all)
            .opacity(backgroundOpacity)
    }

    var cardView: some View {
        content
            .padding([.top, .bottom], horizontalContentInset)
            .padding([.leading, .trailing], verticalContentInset)
            .background(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .foregroundColor(cardBackgroundColor)
                    .cardShadowTooltip()
            )
            .padding(screenEdgePadding)
//            .offset(x: 0, y: cardYOffsetFromMiddle)
    }
}

struct Popup_Previews: PreviewProvider {
    static var previews: some View {
        PopupView(isPresented: .constant(true)) {
            Text("Hello world!")
        }
    }
}

