//
//  AssetsViewModel.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 13.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

struct TokenBalance: Identifiable {
    var id: String {
        address
    }
    var imageURL: URL {
        URL(string: "https://gnosis-safe-token-logos.s3.amazonaws.com/\(address).png")!
    }
    let address: String
    let balance: String
    let balanceUsd: String
}

class AssetsViewModel: ObservableObject {
    @Published var balances = [TokenBalance]()
    @Published var isLoading: Bool = true
    @Published var errorMessage: String? = nil

    private var subscribers = Set<AnyCancellable>()

    init() {
        let request = Safe.fetchRequest().selected()
        let selectedSafe = try! CoreDataStack.shared.viewContext.fetch(request).first!
        isLoading = true
        Just(selectedSafe.address!)
            .setFailureType(to: Error.self)
            .flatMap { address in
                Future<[TokenBalance], Error> { promise in
                    DispatchQueue.global().async {
                        do {
                            let balancesResponse = try App.shared.safeTransactionService.safeBalances(at: address)
                            let tokenBalances = balancesResponse.map {
                                TokenBalance(address: $0.tokenAddress ?? "0x0",
                                             balance: $0.balance,
                                             balanceUsd: $0.balanceUsd)
                            }
                            promise(.success(tokenBalances))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .receive(on: RunLoop.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }, receiveValue:{ tokenBalances in
                self.balances = tokenBalances
            })
            .store(in: &subscribers)
    }
}
