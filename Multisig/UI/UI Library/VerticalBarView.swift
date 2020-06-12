//
//  VerticalBarView.swift
//  Multisig
//
//  Created by Moaaz on 6/11/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct VerticalBarView: View {
    let color: Color = .gnoMediumGrey
    let width: CGFloat = 16
    let barWidth: CGFloat = 2

    var body: some View {
        HStack {
            Rectangle().fill(color).frame(width: barWidth)
        }.frame(width: width)
    }
}

struct VerticalBarView_Previews: PreviewProvider {
    static var previews: some View {
        VerticalBarView()
    }
}
