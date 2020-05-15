//
//  LoadableSafeSettingsView.swift
//  Multisig
//
//  Created by Moaaz on 5/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct LoadableSafeSettingsView: View {

    @ObservedObject
    var model: LoadableSafeSettingsViewModel

    init(safe: Safe) {
        model = LoadableSafeSettingsViewModel(safe: safe)
    }
    
    /// when change safe, model object should be changed also 
    var body: some View {
        ZStack(alignment: .center) {
            Rectangle()
                .edgesIgnoringSafeArea(.all)
                .foregroundColor(Color.gnoWhite)

            if model.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            } else if model.errorMessage != nil {
                ErrorText(model.errorMessage!)
            } else {
                BasicSafeSettingsView(safe: model.safe)
            }
        }
    }
    
}
