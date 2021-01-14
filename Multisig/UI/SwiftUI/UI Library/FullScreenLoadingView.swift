//
//  FullScreenLoadingView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct FullScreenLoadingView: View {
    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            ActivityIndicator(isAnimating: .constant(true), style: .large)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
