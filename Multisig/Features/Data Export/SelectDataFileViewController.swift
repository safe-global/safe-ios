//
//  SelectDataFileViewController.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 06.06.24.
//  Copyright © 2024 Core Contributors GmbH. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

class SelectDataFileViewController: UIViewController, UIDocumentPickerDelegate {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!

    var filenameExtension = "safedata"
    var selectedURL: URL?
    var completion: (_ url: URL) -> Void = { _ in }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Select file"
        headerLabel.text = "Select the previously exported data file."
        
        headerLabel.setStyle(.body)
        filenameLabel.setStyle(.subheadline1Medium)
        
        selectButton.setText("Select File", .bordered)
        nextButton.setText("Next", .filled)
        
        updateFile(nil)
    }

    @IBAction func selectFile(_ sender: Any) {
        let uttypes: [UTType] = [UTType(filenameExtension: filenameExtension)!]
        let filePickerVC = UIDocumentPickerViewController(forOpeningContentTypes: uttypes)
        filePickerVC.delegate = self
        present(filePickerVC, animated: true)
    }

    @IBAction func next(_ sender: Any) {
        if let url = selectedURL {
            completion(url)
        } else {
            assertionFailure("URL must be selected")
        }
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        updateFile(urls.first)
    }

    func updateFile(_ url: URL?) {
        selectedURL = url

        if let name = url?.lastPathComponent, !name.isEmpty {
            filenameLabel.text = name
        } else {
            filenameLabel.text = "No file selected"
        }
        
        nextButton.isEnabled = url != nil
    }
}
