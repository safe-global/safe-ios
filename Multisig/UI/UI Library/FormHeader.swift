//
//  FormHeader.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct FormHeader: View {

    var title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title).font(Font.gnoHeadline).foregroundColor(.gnoDarkBlue)
    }
}

struct FormHeader_Previews: PreviewProvider {
    static var previews: some View {
        FormHeader("Hey this is a form header")
    }
}
