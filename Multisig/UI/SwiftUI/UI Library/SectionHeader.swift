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
                .font(.caption2)
                .foregroundColor(Color.labelTertiary)
                .padding()
            
            Spacer()
        }
        .frame(height: text.isEmpty ? 28 : 44)
        .background(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

struct ListSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        SectionHeader("Test")
    }
}
