//
//  ENSNameForm.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 20.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct ENSNameForm: View {

    @Binding var text: String?
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ENSNameForm_Previews: PreviewProvider {
    static var previews: some View {
        ENSNameForm(text: .constant("Hello"))
    }
}
