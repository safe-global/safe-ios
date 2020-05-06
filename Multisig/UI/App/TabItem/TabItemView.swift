//
//  TabItemView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TabItemView<Content>: View where Content: View {

    @Environment(\.managedObjectContext) var context: CoreDataContext

    private var showsSafeInfo: Binding<Bool>
    private var content: Content

    @inlinable public init(showsSafeInfo: Binding<Bool>,
                           @ViewBuilder content: () -> Content) {
        self.showsSafeInfo = showsSafeInfo
        self.content = content()
    }

    var body: some View {
        NavigationView {
            content
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarItems(leading: selectButton, trailing: switchButton)
        }
        .environment(\.managedObjectContext, context)
    }

    var selectButton: some View {
        SelectedSafeButton(showsSafeInfo: showsSafeInfo).environment(\.managedObjectContext, context)
    }

    var switchButton: some View {
        SwitchSafeButton().environment(\.managedObjectContext, context)
    }
}

struct TabItemView_Previews: PreviewProvider {
    static var previews: some View {
        TabItemView(showsSafeInfo: .constant(false)) { Text("Hello") }
    }
}
