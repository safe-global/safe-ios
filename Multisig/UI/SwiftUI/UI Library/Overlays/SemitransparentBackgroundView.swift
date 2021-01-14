//
//  SemitransparentBackgroundView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 28.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SemitransparentBackgroundView: View {
    private let backgroundOpacity: Double = 0.2
    
    var body: some View {
        Rectangle()
            .background(Color.black)
            .edgesIgnoringSafeArea(.all)
            .opacity(backgroundOpacity)
    }
}

struct SemitransparentBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        SemitransparentBackgroundView()
    }
}
