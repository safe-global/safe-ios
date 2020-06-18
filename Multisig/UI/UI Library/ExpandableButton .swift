//
//  ExpandableButton .swift
//  Multisig
//
//  Created by Moaaz on 6/17/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ExpandableButton: View {
    @State
    private var expanded: Bool = false

    var title: String
    var value: String

    var body: some View {
        Button(action: {
            self.expanded.toggle()
        }) {
            VStack(alignment: .leading) {
                HStack {
                    ValueText(title)
                    if expanded {
                        Image.chevronUp
                    } else {
                        Image.chevronDown
                    }
                }
                if expanded {
                    BodyText(value)
                }
            }
        }
        .animation(.linear(duration: 0.1))
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExpandableButton__Previews: PreviewProvider {
    static var previews: some View {
        ExpandableButton(title: "Data", value: "Test")
    }
}
