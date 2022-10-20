//
//  ReloadButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ReloadButton: View {
    var height: CGFloat = 30
    var iconRotation = Angle(degrees: 135)
    var reload: () -> Void = {}

    var body: some View  {
            Button(action: reload, label: {
                HStack {
                    Spacer()
                    Image(systemName: "arrow.2.circlepath")
                        .rotationEffect(iconRotation)
                    Text("Reload").font(.button)
                    Spacer()
                }
            })
            .buttonStyle(GNOCustomButtonStyle(color: .labelTertiary))
            .frame(height: height)
    }
}
