//
//  keyValueView.swift
//  Multisig
//
//  Created by Moaaz on 5/15/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct keyValueView: View {
    let key: String
    let value: String
    var body: some View {
        HStack {
            BodyText(key)
            Spacer()
            ValueText(value)
        }
    }
}

struct keyValueView_Previews: PreviewProvider {
    static var previews: some View {
        keyValueView(key: "Key", value: "Value")
    }
}
