//
//  ProgressIndicatorCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ProgressIndicatorCell: View {
    var body: some View {
        ActivityIndicator(isAnimating: .constant(true), style: .medium)
            .frame(idealWidth: .infinity, maxWidth: .infinity, alignment: .center)
    }
}
