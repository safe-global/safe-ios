//
//  SwiftUIView.swift
//  Multisig
//
//  Created by Moaaz on 3/31/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct Headline: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .font(.custom("SF Pro Text Semibold", size: 17))
    }
}

struct Headline_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/.modifier(Headline())
    }
}
