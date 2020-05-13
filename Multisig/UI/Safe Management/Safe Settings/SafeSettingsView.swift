//
//  SafeSettingsView.swift
//  Multisig
//
//  Created by Moaaz on 5/4/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import CoreData

struct SafeSettingsView: View {

    @ObservedObject
    var model: SafeSettingsViewModel

    init(safe: Safe) {
        model = SafeSettingsViewModel(safe: safe)
    }
    
    /// when change safe, model object should be changed also 
    var body: some View {
        ZStack(alignment: .center) {
            if model.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            } else if model.errorMessage != nil {
                ErrorText(model.errorMessage!)
            } else {
                SafeSettingsContentView(safe: model.safe)
            }
        }
    }
    
}
