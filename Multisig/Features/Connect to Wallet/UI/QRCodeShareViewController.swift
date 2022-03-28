//
//  QRCodeShareViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 24.03.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class QRCodeShareViewController: UIViewController {
    @IBOutlet weak var qrCodeView: QRCodeView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!

    var value: String = "" {
        didSet {
            qrCodeView.value = value
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        shareButton.setText("Share Code", .plain)
        saveButton.setText("Save Image", .plain)
        qrCodeView.showsBorder = false
        qrCodeView.imageSizeInPoints = 600
    }

    @IBAction func didTapShare(_ sender: Any) {
        let vc = UIActivityViewController(activityItems: [qrCodeView.value], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, success, _, _ in
            if success {
                App.shared.snackbar.show(message: "QR Code shared.")
            }
        }
        present(vc, animated: true, completion: nil)
    }

    @IBAction func didTapSave(_ sender: Any) {
        guard let image = qrCodeView.imageView.image else { return }
        let vc = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, success, _, _ in
            if success {
                App.shared.snackbar.show(message: "QR Code saved.")
            }
        }
        present(vc, animated: true, completion: nil)
    }
}
