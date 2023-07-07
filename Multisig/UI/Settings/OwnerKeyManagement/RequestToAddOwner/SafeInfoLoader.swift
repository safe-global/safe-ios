//
//  SafeInfoLoader.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation

// Loads safe info from the backend and Safe Account owners from the blockchain
// and combines two results so that the owners addresses are up-to-date with the
// blockchain.
class SafeInfoLoader {

    private var chain: Chain!
    private var address: Address!

    private var tasks: [URLSessionTask?]!

    private var safeInfo: SCGModels.SafeInfoExtended?
    private var owners: [Address]?

    private var errors: [Error]!

    private var completion: (Result<SCGModels.SafeInfoExtended, Error>) -> Void = { _ in }

    // if you cancel, you won't receive completion call back.
    func cancel() {
        for task in tasks {
            task?.cancel()
        }
    }

    // call this
    func load(chain: Chain, safe: Address, completion: @escaping (Result<SCGModels.SafeInfoExtended, Error>) -> Void) {
        self.chain = chain
        self.address = safe
        self.completion = completion
        DispatchQueue.global().async { [unowned self] in
            self.load()
        }
    }

    private func load() {
        assert(chain != nil)
        assert(address != nil)

        tasks = []
        errors = []

        loadSafeInfo()
    }

    private func handleLoadedData() {
        guard errors.isEmpty else {
            dispatchOnMainThread({ [unowned self] in
                completion(.failure(errors.first!))
            }())
            return
        }

        guard var safeInfo = safeInfo, let owners = owners else {
            // cancelled, just silently stop.
            LogService.shared.debug("Safe Loading cancelled")
            return
        }

        // substitute server response with the up-to-date blockchain data of the owners
        safeInfo.owners = owners.map { address in
            SCGModels.AddressInfo(value: AddressString(address))
        }

        dispatchOnMainThread({ [unowned self] in
            completion(.success(safeInfo))
        }())
    }

    private func loadSafeInfo() {
        safeInfo = nil
        let task = App.shared.clientGatewayService.asyncSafeInfo(safeAddress: address, chainId: chain.id!) { [weak self] result in
            self?.handleAsyncResult(result: result, success: { info in
                self?.safeInfo = info

                // only if successful, load owners
                self?.loadOwners()
            })
        }
        tasks.append(task)
    }

    private func loadOwners() {
        owners = nil
        let task = SafeTransactionController.shared.getOwners(safe: address, chain: chain) { [weak self] result in
            self?.handleAsyncResult(result: result, success: { addresses in
                self?.owners = addresses

                // on success, process results
                self?.handleLoadedData()
            })
        }
        tasks.append(task)
    }

    private func handleAsyncResult<R,E>(result: Result<R, E>, success: (R) -> Void) {
        do {
            let value = try result.get()
            success(value)
        } catch let nsError as NSError where nsError.code == URLError.Code.cancelled.rawValue && nsError.domain == NSURLErrorDomain {
            // ignore cancellation errors
            LogService.shared.debug("Cancelled URL loading")
        } catch {
            errors.append(GSError.detailedError(from: error))
            handleLoadedData()
        }
    }
}
