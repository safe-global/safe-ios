////
////  FullScreenBackground.swift
////  Multisig
////
////  Created by Dmitry Bespalov on 07.10.20.
////  Copyright © 2020 Gnosis Ltd. All rights reserved.
////
//
//import SwiftUI
//
//struct FullScreenBackground: ViewModifier {
//    var color: Color
//    func body(content: Content) -> some View {
//        ZStack(alignment: .center) {
//            Rectangle()
//                .edgesIgnoringSafeArea(.all)
//                .foregroundColor(color)
//
//            content
//        }
//    }
//}
//
//extension View {
//    func fullScreenBackground(_ color: Color = Color.gnoWhite) -> some View {
//        modifier(FullScreenBackground(color: color))
//    }
//}
