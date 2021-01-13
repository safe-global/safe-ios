//
//  ListSectionHeader.swift
//  Multisig
//
//  Created by Moaaz on 5/5/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SectionHeader: View {
    
    var text: String

    init(_ label: String) {
        text = label
    }
    
    var body: some View {
        HStack {
            Text(text)
                .tracking(2)
                .font(.gnoCaption2)
                .foregroundColor(Color.gnoMediumGrey)
                .padding()
            
            Spacer()
        }
        .frame(height: 44)
        .background(Color.gnoWhite)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

struct ListSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeader("Test")
    }
}
