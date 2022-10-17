//
//  NoDataView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct NoDataView: View {
    var reload: () -> Void = {}

    var body: some View {
        VStack {
            ReloadButton(reload: reload)
                .padding(.top, 20)

            HStack {
                Image("ico-server-error")
                Text("Data cannot be loaded").font(.title3).foregroundColor(.labelTertiary)
            }
            .padding(.top, 115)

            Spacer()
        }
    }
}
