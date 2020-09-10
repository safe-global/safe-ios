//
//  SafeHeaderView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 19.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeHeaderView: View {
    @Binding
    var showsSafeInfo: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .foregroundColor(Color.gnoSnowwhite)
                .gnoShadow()
            HStack {
                selectButton
                Spacer()
                switchButton
            }
            .padding()
        }
    }

    var selectButton: some View {
        SelectedSafeButton(showsSafeInfo: $showsSafeInfo)
    }

    var switchButton: some View {
        SwitchSafeButton()
    }
}

// because of the TestCoreDataStack available only in Debug
#if DEBUG

struct SafeHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        SafeHeaderView(showsSafeInfo: .constant(false))
            .environment(\.managedObjectContext, TestCoreDataStack().viewContext)
    }
}

#endif
