//
//  ExportDataFlow.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 03.06.24.
//  Copyright © 2024 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class ExportDataFlow: UIFlow {
    
    override func start() {
        instructions()
    }
    
    func instructions() {
        let vc = CommonInstructionsViewController()
        vc.title = "Export Data"
        
        vc.trackingEvent = .screenExportInstructions
        
        vc.steps = [
            .header,
            .step(number: "1", title: "Create a file password", description: "Enter a strong password for locking the export file."),
            .step(number: "2", title: "Export the data", description: "Data includes the owner keys, safes and address book in an encrypted file format."),
            .step(number: "3", title: "Save the data file", description: "Store the export file in Files on your device or a secure location of your choice."),
            .finalStep(title: "Export of data completed!")
        ]
        
        vc.onClose = { [unowned self] in
            stop(success: false)
        }
        
        vc.onStart = { [unowned self] in
            createPassword()
        }
        
        show(vc)
    }
    
    func createPassword() {
        let vc = CreateExportPasswordViewController(nibName: nil, bundle: nil)
        vc.title = "Create password"
        vc.prompt = "Choose a password for protecting the exported data."
        vc.placeholder = "Enter password"
        vc.completion = { [unowned self] plainTextPassword in
            repeatPassword(plainTextPassword)
        }
        show(vc)
    }

    func repeatPassword(_ password: String) {
        let vc = CreateExportPasswordViewController(nibName: nil, bundle: nil)
        vc.title = "Repeat password"
        vc.placeholder = "Repeat password"
        vc.prompt = "Repeat previously entered password"
        vc.validateValue = { value in
            if value != password {
                return "Passwords do not match"
            }
            return nil
        }
        vc.completion = { [unowned self] confirmedPassword in
            exportData(confirmedPassword)
        }
        show(vc)
    }

    func exportData(_ password: String) {
        let vc = ExportInProgressViewController(nibName: nil, bundle: nil)
        vc.userPassword = password
        vc.completion = { [weak self] result in
            self?.saveExportedData(tempFileURL: result.tempFileURL, logs: result.logs)
        }
        show(vc)
    }
    
    func saveExportedData(tempFileURL: URL?, logs: [String]) {
        if let url = tempFileURL {
            let vc = SuccessViewController(
                titleText: "Export completed",
                bodyText: "Exported data is encrypted and includes owner keys, list of safes and address book",
                primaryAction: "Save",
                secondaryAction: "Done"
            )
            vc.reenablesNavBar = false
            vc.setTrackingData(trackingEvent: .screenExportSuccess)
            
            vc.onDone = { [weak self, unowned vc] isPrimary in
                if isPrimary {
                    let shareVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                    vc.present(shareVC, animated: true)
                } else {
                    ImportExportDataController.removeTemporaryFile(url)
                    self?.stop(success: true)
                }
            }
            
            show(vc)
        } else {
            let vc = ErrorViewController(nibName: nil, bundle: nil)
            vc.titleText = "Export failed"
            vc.bodyText = "Details are shown below:"
            vc.errorText = logs.joined(separator: "\n")
            if vc.errorText.isEmpty {
                vc.errorText = "No error messages"
            }
            vc.completion = { [weak self] in
                self?.stop(success: false)
            }
            navigationController.isNavigationBarHidden = true
            show(vc)
        }
    }
}

class CommonInstructionsViewController: InstructionsViewController {
    var onStart: (() -> Void)?
    var trackingEvent: TrackingEvent?

    convenience init() {
        self.init(namedClass: InstructionsViewController.self)
    }
    
    override func didTapButton(_ sender: Any) {
        onStart?()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let trackingEvent = trackingEvent {
            Tracker.trackEvent(trackingEvent)
        }
    }
}
