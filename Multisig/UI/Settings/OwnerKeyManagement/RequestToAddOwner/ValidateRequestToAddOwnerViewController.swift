//
//  ValidateRequestToAddOwnerViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 14.06.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ValidateRequestToAddOwnerViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!

    var parameters: AddOwnerRequestParameters!
    var safeLoader = SafeInfoLoader()
    var onCancel: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.addCloseButton(self)

        descriptionLabel.setStyle(.primary)

        cancelButton.setText("Cancel", .plain)
    }

    override func closeModal() {
        cancel()
    }

    @IBAction func didTapCancelButton(_ sender: Any) {
        cancel()
    }

    func validate() {
        safeLoader.load(chain: parameters.chain, safe: parameters.safeAddress) { [weak self] result in
            self?.handle(result: result)
        }
    }

    func handle(result: Result<SCGModels.SafeInfoExtended, Error>) {
        do {
            let info = try result.get()

            #error("Continue from here")

            // update database

            // is owner in the list?
                // show inactive link

            // do I not have safe?
                // show no safe

            // is safe read only?
                // show safe read only

            // all passed
                // show the 'receive'

        } catch {
            // show error screen
        }
    }

    func cancel() {
        safeLoader.cancel()
    }

}

// Loads safe info from the backend and safe owners from the blockchain
// and combines two results so that the owners addresses are up-to-date with the
// blockchain.
class SafeInfoLoader {

    private var chain: Chain!
    private var address: Address!

    private var tasks: [URLSessionTask?]!
    private var group: DispatchGroup!
    private var timeout = 60

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
        group = DispatchGroup()

        loadSafeInfo()
        loadOwners()

        // blocking call
        let result = group.wait(timeout: .now() + .seconds(timeout))

        switch result {
        case .success:
            // will handle in a separate method
            break

        case .timedOut:
            errors.append(GSError.LoadSafeTimedOut())
        }

        handleLoadedData()
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
        group.enter()
        let task = App.shared.clientGatewayService.asyncSafeInfo(safeAddress: address, chainId: chain.id!) { [weak self] result in
            self?.handleAsyncResult(result: result, success: { info in
                self?.safeInfo = info
            })
        }
        tasks.append(task)
    }

    private func loadOwners() {
        owners = nil
        group.enter()
        let task = SafeTransactionController.shared.getOwners(safe: address, chain: chain) { [weak self] result in
            self?.handleAsyncResult(result: result, success: { addresses in
                self?.owners = addresses
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
        }

        group.leave()
    }
}
