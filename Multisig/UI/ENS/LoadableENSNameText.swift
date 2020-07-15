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
    @ObservedObject private var ensLoader: ENSNameLoader
    private var placeholder: String
    private var showsLoading: Bool

    init(safe: Safe, placeholder: String = "", showsLoading: Bool = true) {
        self.safe = safe
        self.placeholder = placeholder
        self.showsLoading = showsLoading
        self.ensLoader = ENSNameLoader(safe: safe)
    }

    var body: some View {
        ZStack {
            if ensLoader.isLoading && showsLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .medium)
            } else if !ensLoader.isLoading && !displayValue.isEmpty {
                Text(displayValue)
                    .headline()
            }
        }
    }

    var displayValue: String {
        safe.displayENSName.isEmpty ? placeholder : safe.displayENSName
    }
}
