//
//  EmptyTransactionsView.swift
//  Multisig
//
//  Created by Moaaz on 5/27/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct EmptyListPlaceholder: View {
    let label: String
    let image: String
    var body: some View {
        VStack (spacing: 15) {
            Image(image)
            Text(label).title()
        }.offset(y: -100)
    }
}

struct EmptyTransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyListPlaceholder(label: "test", image: "test")
    }
}
