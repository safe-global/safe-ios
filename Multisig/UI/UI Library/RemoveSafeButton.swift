//
//  RemoveSafeButton.swift
//  Multisig
//
//  Created by Moaaz on 5/13/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct RemoveSafeButton: View {
    
    var safe: Safe
    
    @State
    var showDeleteConfirmation: Bool = false
    
    var body: some View {
        Button(action: {
            self.showDeleteConfirmation.toggle()
        }) {
            HStack {
                Image(systemName: "trash").font(Font.gnoBody.bold())
                Text("Remove Safe").font(.gnoHeadline)
                Spacer()
            }
            .padding()
        }
        .foregroundColor(Color.gnoTomato)
        .buttonStyle(BorderlessButtonStyle())
        .background(Color.gnoWhite)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        .actionSheet(isPresented: $showDeleteConfirmation) {
            ActionSheet(title: Text(""), message: Text("Removing a Safe only removes it from this app. It does not delete the Safe from the blockchain. Funds will not get lost."), buttons: [
                .destructive(Text("Remove")) {
                    Safe.remove(safe: self.safe)
                    ViewState.shared.state = .balanaces
                },
                .cancel()
            ])
        }
    }
}

struct RemoveSafeButton_Previews: PreviewProvider {
    static var previews: some View {
        RemoveSafeButton(safe: Safe())
    }
}
