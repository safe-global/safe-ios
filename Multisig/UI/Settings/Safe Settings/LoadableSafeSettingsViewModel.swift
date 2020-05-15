//
//  LoadableSafeSettingsViewModel.swift
//  Multisig
//
//  Created by Moaaz on 5/6/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Combine

class LoadableSafeSettingsViewModel: ObservableObject {
    
    @Published
    var isLoading: Bool = true

    @Published
    var errorMessage: String? = nil

    @Published
    var safe: Safe

    private var subscribers = Set<AnyCancellable>()

    init(safe: Safe) {
        isLoading = true
        self.safe = safe
        // assuming that if address exists, it is a valid address
        // which we validated before.
        Just(safe.address)
            .tryCompactMap { $0 }
            .flatMap { address in
                Future { promise in
                    DispatchQueue.global().async {
                        do {
                            let safeInfo = try Safe.download(at: address)
                            promise(.success(safeInfo))
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
            }, receiveValue: { response in
                safe.update(from: response)
            })
            .store(in: &subscribers)
    }
    
}

extension Safe {

    func update(from safeInfo: SafeStatusRequest.Response) {
        objectWillChange.send()
        threshold = safeInfo.threshold
        owners = safeInfo.owners
        masterCopy = safeInfo.masterCopy
        version = safeInfo.version
        nonce = safeInfo.nonce
        modules = safeInfo.modules
        fallbackHandler = safeInfo.fallbackHandler
    }

}
