//
//  RejectionConfirmationViewController.swift
//  Multisig
//
//  Created by Moaaz on 2/20/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class RejectionConfirmationViewController: UIViewController {

    @IBOutlet weak var rejectionButton: UIButton!
    @IBOutlet weak var readMoreLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    private var rejectTask: URLSessionTask?
    private var transaction: SCGModels.TransactionDetails!

    convenience init(transaction: SCGModels.TransactionDetails) {
        self.init(namedClass: RejectionConfirmationViewController.self)
        self.transaction = transaction
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rejectionButton.setText("Reject transaction", .filledError)
        navigationItem.title = "Reject Transaction"
        readMoreLabel.setStyle(.primary)
        descriptionLabel.setStyle(.primary)
        // Do any additional setup after loading the view.
    }

    @IBAction func rejectButtonTouched(_ sender: Any) {
        do {
            let safeAddress = try Safe.getSelected()!.addressValue
            let tx = Transaction.rejectionTransaction(safeAddress: safeAddress, nonce: transaction.multisigInfo!.nonce)
            let signature = try SafeTransactionSigner().sign(tx, by: safeAddress)
            rejectTask = App.shared.clientGatewayService.propose(transaction: tx, safeAddress: AddressString(safeAddress), sender: AddressString(signature.signer)!, signature: signature.value, completion: { [weak self] result in

                // NOTE: sometimes the data of the transaction list is not
                // updated right away, we'll give a moment for the backend
                // to catch up before finishing with this request.
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(600)) { [weak self] in
                    if case Result.success(_) = result {
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .transactionDataInvalidated, object: nil)
                            //Tracker.shared.track(event: TrackingEvent.transactionDetailsTransactionConfirmed)
                            App.shared.snackbar.show(message: "Rejection successfully submitted")
                        }
                    }

                    //self?.onLoadingCompleted(result: result)
                }
            })
        } catch {
            //App.shared.snackbar.show(error: "Failed to Reject transaction")
        }
    }
}
