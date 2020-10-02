//
//  LoadingSafeSettingsView.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SafeSettingsContent: View {
    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selected: FetchedResults<Safe>

    var body: some View {
        ZStack {
            if selected.first == nil {
                // so it does not jump when switching Assets <-> Settings in the tap bar
                AddSafeIntroView(padding: .top, -56).onAppear {
                    self.trackEvent(.settingsSafeNoSafe)
                }
            } else {
                ZStack(alignment: .center) {
                    Rectangle()
                        .edgesIgnoringSafeArea(.all)
                        .foregroundColor(Color.gnoWhite)

                    LoadingSafeSettingsView(safe: selected.first!)
                }
            }
        }
    }
}

struct LoadingSafeSettingsView: View {
    @ObservedObject
    var safe: Safe
    @ObservedObject var model = LoadingSafeSettingsViewModel()
    var status: ViewLoadingStatus { model.status }

    @ViewBuilder
    var body: some View {
        if status == .initial {
            Text("Loading...").onAppear(perform: reload)
        } else if status == .loading {
            FullScreenLoadingView()
        } else if status == .failure {
            NoDataView(reload: reload)
        } else if status == .success {
            SafeSettingListView(safe: $model.safe, reload: reload)
        }
    }

    func reload() {
        model.reload(safe: safe)
    }
}

struct SafeSettingListView: View {
    @Binding var safe: Safe!
    var reload: () -> Void = {}

    let rowHeight: CGFloat = 48

    var body: some View {
        if safe == nil {
            Text("Loading...")
        } else {
            List {
                ReloadButton(reload: reload)

                Section(header: SectionHeader("SAFE NAME")) {
                    NavigationLink(
                        destination:
                            EditSafeNameView(
                                address: safe.address ?? "",
                                name: safe.name ?? ""),
                        label: {
                            Text(safe.name ?? "").body()
                        })
                        .frame(height: rowHeight)
                }

                Section(header: SectionHeader("REQUIRED CONFIRMATIONS")) {
                    Text("\(String(describing: safe.threshold ?? 0)) out of \(safe.owners?.count ?? 0)")
                        .body()
                        .frame(height: rowHeight)
                }

                Section(header: SectionHeader("OWNER ADDRESSES")) {
                    ForEach(safe.owners ?? [], id: \.self, content: { owner in
                        AddressCell(address: owner.checksummed)
                    })
                }

                Section(header: SectionHeader("CONTRACT VERSION")) {
                    ContractVersionCell(implementation: safe.implementation?.checksummed)
                }

                Section(header: SectionHeader("ENS NAME")) {
                    LoadableENSNameText(safe: safe, placeholder: "Reverse record not set")
                        .frame(height: rowHeight)
                }

                Section(header: SectionHeader("")) {
                    NavigationLink(destination: AdvancedSafeSettingsView(safe: safe)) {
                        Text("Advanced").body()
                    }
                    .frame(height: rowHeight)

                    RemoveSafeButton(safe: self.safe)
                }
            }
            .listStyle(GroupedListStyle())

        }
    }

}


import Combine
class LoadingSafeSettingsViewModel: ObservableObject {

    @Published
    var safe: Safe?

    @Published
    var status: ViewLoadingStatus = .initial

    var subscribers = Set<AnyCancellable>()

    func reload(safe: Safe) {
        guard status != .loading else { return }
        status = .loading
        Just(safe.address)
            .compactMap { $0 }
            .compactMap { Address($0) }
            .receive(on: DispatchQueue.global())
            .tryMap {  address -> SafeStatusRequest.Response in
                let safeInfo = try Safe.download(at: address)
                return safeInfo
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let `self` = self else { return }
                if case .failure(let error) = completion {
                    App.shared.snackbar.show(message: error.localizedDescription)
                    self.status = .failure
                } else {
                    self.status = .success
                }
            }, receiveValue: { [weak self, weak safe] response in
                guard let `self` = self, let safe = safe else { return }
                safe.update(from: response)
                if self.safe == nil {
                    self.safe = safe
                }
            })
            .store(in: &subscribers)
    }

}
