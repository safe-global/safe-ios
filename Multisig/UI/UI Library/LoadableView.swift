//
//  LoadableView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 24.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

protocol LoadableViewModel: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    func reloadData()
}

protocol Loadable: View {
    associatedtype LoadableModel: LoadableViewModel
    var model: LoadableModel { get }
}

struct LoadableView<Content: Loadable>: View {
    private let content: Content

    @ObservedObject
    private var model: Content.LoadableModel

    init(_ content: Content) {
        self.content = content
        self.model = content.model
    }

    var body: some View {
        ZStack(alignment: .center) {
            if model.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            } else if model.errorMessage != nil {
                noDataView
            } else {
                content
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.model.reloadData()
        }
    }

    var noDataView: some View {
        VStack {
            HStack {
                Image("ico-server-error")
                TitleText("Data cannot be loaded", color: .gnoMediumGrey)
            }
            .padding(.top, 135)

            Spacer()
        }
    }
}
