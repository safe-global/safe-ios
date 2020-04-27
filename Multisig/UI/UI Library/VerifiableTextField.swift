//
//  VerifiableTextField.swift
//  Multisig
//
//  Created by Moaaz on 4/20/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct VerifiableTextField: View {
    var name: String
    var validator: (String) -> String
    
    @State private var text: String = ""
    
    var body: some View {
        let errorMessage = validator(text)
        let height: CGFloat = 56
        var foregroundColor = Color.gnoDarkGrey
        var borderColor = Color.gnoWhitesmoke
        
        if !errorMessage.isEmpty {
            foregroundColor = Color.gnoTomato
            borderColor = Color.gnoTomato
        }
        
        return VStack (alignment: .leading) {
            HStack {
                TextField(name, text: $text)
                    .foregroundColor(foregroundColor)
                    .frame(height: height)
                    .font(.gnoBody)
                if errorMessage.isEmpty {
                    Image("ico-circle-check")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: 2)
                    .frame(height: height)
            )
            
            Text(errorMessage)
                .font(.gnoCallout)
                .foregroundColor(Color.gnoTomato)
                .frame(alignment: .leading)
        }
    }
}

struct VerifiableTextField_Previews: PreviewProvider {
    static var previews: some View {
        VerifiableTextField(name: "Enter name") { input in
            return "input can't be empty"
        }
    }
}
