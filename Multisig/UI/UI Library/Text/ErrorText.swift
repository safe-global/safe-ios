//
//  ErrorText.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 04.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ErrorText: View {

    var label: String

    var body: some View {
        Text(label)
            .font(Font.gnoBody.weight(.medium))
            .foregroundColor(Color.gnoTomato)
            .padding(.leading)
    }
}

struct ErrorText_Previews: PreviewProvider {
    static var previews: some View {
        ErrorText(label: "Error message")
    }
}
