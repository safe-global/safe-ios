//
//  Popup.swift
//  Multisig
//
//  Created by Moaaz on 4/30/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct PopupContainer: View {
    
    var content: AnyView
    var dismissHandler: () -> ()
    var contentWidth: CGFloat = 290
    var contentHeight: CGFloat = 350
    var backgroundOpacity: Double = 0.2
    
    var body: some View {
        ZStack(alignment: .center) {
            
            background
                .transition(.opacity)
                .animation(.easeInOut)
                .onTapGesture(perform: dismissHandler)
            
            content
                .frame(width: contentWidth, height: contentHeight)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(Color.white)
                        .shadow(radius: 10)
                )
                .transition(
                    AnyTransition.move(edge: .bottom)
                        .animation(.spring())
                        .combined(with:.opacity)
                )
        }
    }

    var background: some View {
        Rectangle()
            .background(Color.black)
            .edgesIgnoringSafeArea(.all)
            .opacity(backgroundOpacity)
    }
}

struct Popup_Previews: PreviewProvider {
    static var previews: some View {
        PopupContainer(content: AnyView(Text("Hello World")), dismissHandler: {})
    }
}

