//
//  LoadableENSNameText.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct LoadableENSNameText: View {

    @ObservedObject var safe: Safe
    @ObservedObject private var ensLoader = ENSNameLoader()

    init(safe: Safe) {
        self.safe = safe
        self.ensLoader.load(safe: self.safe)
    }

    var body: some View {
        Group {
            if ensLoader.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
            } else if safe.displayENSName.isEmpty {
                Text("Reverse resolved ENS name not found")
                    .font(Font.gnoCallout)
                    .foregroundColor(Color.gnoMediumGrey)
            } else {
                BoldText(safe.displayENSName)
            }
        }
    }
}
