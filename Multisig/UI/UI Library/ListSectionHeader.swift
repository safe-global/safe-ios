//
//  ListSectionHeader.swift
//  Multisig
//
//  Created by Moaaz on 5/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ListSectionHeader: View {
    var text: String
    
    var body: some View {
        Text(text)
        .tracking(2)
            .font(.gnoCaption2)
            .foregroundColor(Color.gnoMediumGrey).padding([.top, .bottom])
            .background(Color.clear)
    }
}

struct ListSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        ListSectionHeader(text: "Test")
    }
}
