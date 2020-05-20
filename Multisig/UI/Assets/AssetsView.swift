//
//  AssetsView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 18.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct AssetsView: View {
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selectedSafe: FetchedResults<Safe>

    var body: some View {
        ZStack {
            if selectedSafe.first != nil {
                CoinsView(safe: selectedSafe.first!)
            } else {
                AddSafeIntroView()
            }
        }
    }
}

struct AssetsView_Previews: PreviewProvider {
    static var previews: some View {
        AssetsView()
    }
}
