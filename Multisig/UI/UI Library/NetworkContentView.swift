//
//  NetworkContentView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 07.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

// View that is able to load the content from network
struct NetworkContentView<Content: View>: View {
    var status: ViewLoadingStatus
    var reload: () -> Void = { }
    var content: () -> Content
    var body: some View {
        switch status {
        case .initial:
            Text("Loading...").onAppear(perform: reload)
        case .loading:
            FullScreenLoadingView()
        case .failure:
            NoDataView(reload: reload)
        case .success:
            content()
        }
    }
}

enum ViewLoadingStatus {
    case initial, loading, success, failure
}
