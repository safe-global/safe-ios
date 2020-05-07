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
    private var placeholder: String

    init(safe: Safe, placeholder: String) {
        self.safe = safe
        self.placeholder = placeholder
        self.ensLoader.load(safe: self.safe)
    }

    var body: some View {
        Group {
            if ensLoader.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
            } else {
                BoldText(safe.displayENSName.isEmpty ? placeholder : safe.displayENSName)
            }
        }
    }
}
