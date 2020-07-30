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

    private let horizontalContentInset: CGFloat = Spacing.extraLarge

    private let onAppearCardScale: CGFloat = 0.95
    private let cardYOffsetFromMiddle: CGFloat = -90

    private let verticalContentInset: CGFloat = Spacing.medium
    private let screenEdgePadding: CGFloat = Spacing.medium

    private let cardCornerRadius: CGFloat = 10

    private let cardBackgroundColor = Color.white

    public init(isPresented: Binding<Bool>,
               @ViewBuilder content: () -> Content) {
        self.content = content()
        self.isPresented = isPresented
    }

    var body: some View {
        ZStack(alignment: .center) {
            if isPresented.wrappedValue {
                SemitransparentBackgroundView()
                    .transition(AnyTransition.opacity.animation(.easeInOut))
                    .onTapGesture {
                        // using withAnimation actually animates the transitioning
                        withAnimation {
                            self.isPresented.wrappedValue.toggle()
                        }
                    }

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
    }
}

struct Popup_Previews: PreviewProvider {
    static var previews: some View {
        PopupView(isPresented: .constant(true)) {
            Text("Hello world!")
        }
    }
}

