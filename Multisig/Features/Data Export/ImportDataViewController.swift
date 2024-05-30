//
//  ImportDataViewController.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 29.05.24.
//  Copyright © 2024 Gnosis Ltd. All rights reserved.
//

import UIKit
import UniformTypeIdentifiers

class ImportDataViewController: UIViewController, UIDocumentPickerDelegate, UITextFieldDelegate, PasscodeProtecting {
    
    var importController = ImportExportDataController()
    
    @IBOutlet weak var filePasswordTextField: UITextField!
    @IBOutlet weak var pastePasswordButton: UIButton!
    @IBOutlet weak var selectFileButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var fileSelectionStatusLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    
    var fileContents: Data?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Import Data"
        
        filePasswordTextField.delegate = self
    }
    
    func indicateStarted() {
        activityView.startAnimating()
        startButton.isEnabled = false
        filePasswordTextField.isEnabled = false
        pastePasswordButton.isEnabled = false
        selectFileButton.isEnabled = false
    }
    
    func indicateStopped() {
        activityView.stopAnimating()
        startButton.isEnabled = true
        filePasswordTextField.isEnabled = true
        pastePasswordButton.isEnabled = true
        selectFileButton.isEnabled = true
    }

    @IBAction func pastePassword() {
        filePasswordTextField.text = Pasteboard.string
    }
    
    @IBAction func selectFile() {
        let uttypes: [UTType] = [UTType(filenameExtension: "safedata")!]
        let filePickerVC = UIDocumentPickerViewController(forOpeningContentTypes: uttypes)
        filePickerVC.delegate = self
        present(filePickerVC, animated: true)
    }
    
    @IBAction func startImport() {
        authenticate { [weak self] success in
            if success {
                self?.startDataImport()
            }
        }
    }
    
    func startDataImport() {
        guard let fileContents = fileContents, let filePassword = filePasswordTextField.text, let key = Data(base64Encoded: filePassword) else {
            return
        }
        indicateStarted()
        Task { @MainActor in
            do {
                let data = fileContents
                let file = try JSONDecoder().decode(SecuredDataFile.self, from: data)
                await importController.importEncrypted(file: file, key: key)
                let logs = importController.logs
                
                let resultsVC = ImportResultsViewController(nibName: nil, bundle: nil)
                resultsVC.logs = logs
                let nav = ViewControllerFactory.modal(viewController: resultsVC)
                
                resultsVC.completion = { [weak self] in
                    self?.dismiss(animated: true, completion: { [weak self] in
                        self?.navigationController?.popViewController(animated: true)
                    })
                }
                
                indicateStopped()
                present(nav, animated: true)
            } catch {
                LogService.shared.error("Failed to import: \(error)")
            }
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, url.startAccessingSecurityScopedResource() else {
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        fileSelectionStatusLabel.text = url.lastPathComponent
        
        var error: NSError? = nil
        NSFileCoordinator().coordinate(readingItemAt: url, error: &error) { fileURL in
            
            guard fileURL.startAccessingSecurityScopedResource() else {
                return
            }
            do {
                fileContents = try Data(contentsOf: fileURL)
            } catch {
                LogService.shared.error("Failed to read file: \(error)")
            }
            
            fileURL.stopAccessingSecurityScopedResource()
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
