//
//  ExpandableButton .swift
//  Multisig
//
//  Created by Moaaz on 6/17/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ExpandableButton: View {

    var title: String
    var value: String
    var enableCopy: Bool = true
    
    var body: some View {
        ExpandableView(title: Text(title).body(.gnoDarkGrey),
                       value: copyableValue)
    }

    var copyableValue: some View {
        CopyButton(value) {
            Text(value).body()
        }.disabled(!enableCopy)
    }
}

struct ExpandableView<Title: View, Value: View>: View {
    @State private var expanded: Bool = false

    var title: Title
    var value: Value

    var body: some View {
        Button(action: { self.expanded.toggle() }) {
            VStack(alignment: .leading) {
                HStack {
                    title

                    if expanded {
                        Image.chevronUp
                    } else {
                        Image.chevronDown
                    }
                }
                if expanded {
                    value
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
