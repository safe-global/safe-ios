//
//  FullSize.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct FullSize<Content> : View where Content : View {

    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()

                content

                Spacer()
            }
            Spacer()
        }
    }
}


struct FullSize_Previews: PreviewProvider {
    static var previews: some View {
        FullSize { Text("Hello") }
    }
}
