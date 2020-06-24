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

protocol LoadableView: View {
    associatedtype LoadableModel: LoadableViewModel
    var model: LoadableModel { get }
}

struct Loadable<V: LoadableView>: View {
    private let view: V

    @ObservedObject
    private var model: V.LoadableModel

    init(_ view: V) {
        self.view = view
        self.model = view.model
    }

    var body: some View {
        ZStack(alignment: .center) {
            if model.isLoading {
                ActivityIndicator(isAnimating: .constant(true), style: .large)
            } else if model.errorMessage != nil {
                noDataView
            } else {
                view
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
                Text("Data cannot be loaded").font(Font.gnoTitle3).foregroundColor(.gnoMediumGrey)
            }
            .padding(.top, 135)

            Spacer()
        }
    }
}
