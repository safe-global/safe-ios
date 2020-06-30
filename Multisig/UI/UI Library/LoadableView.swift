//
//  LoadableView.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 24.06.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI
import Combine

protocol LoadableViewModel: ObservableObject {
    var isLoading: Bool { get set }
    var isRefreshing: Bool { get set }
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
        GeometryReader { geometryProxy in
            RefreshableScrollView(refreshing: self.$model.isRefreshing) {
                ZStack(alignment: .center) {
                    if self.model.isLoading {
                        ActivityIndicator(isAnimating: .constant(true), style: .large)
                    } else if self.model.errorMessage != nil {
                        self.noDataView
                    } else {
                        self.content
                    }
                }
                .frame(height: geometryProxy.size.height)
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

class BasicLoadableViewModel: LoadableViewModel {
    @Published var isLoading: Bool = true

    @Published var isRefreshing: Bool = false {
        didSet {
            if oldValue == false && isRefreshing == true {
                self.reloadData()
            }
        }
    }

    @Published var errorMessage: String? = nil

    var subscribers = Set<AnyCancellable>()

    final func reloadData() {
        subscribers.forEach { $0.cancel() }
        isLoading = !isRefreshing
        reload()
    }

    func reload() {
        preconditionFailure("Should be overriden")
    }
}
