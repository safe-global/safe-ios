//
//  ImportDataFlow.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 06.06.24.
//  Copyright © 2024 Core Contributors GmbH. All rights reserved.
//

import Foundation
import UIKit

class ImportDataFlow: UIFlow {
    
    override func start() {
        instructions()
    }
    
    func instructions() {
        let vc = CommonInstructionsViewController()
        vc.title = "Import Data"
        vc.trackingEvent = .screenImportInstructions
        
        vc.steps = [
            .header,
            .step(number: "1", title: "Select the data file",
                  description: "Choose a *.safedata file that was exported before"),
            .step(number: "2", title: "Enter file password",
                  description: "Enter the password to access the data from the file"),
            .step(number: "3", title: "Import the data",
                  description: "The imported data includes owner keys, safes and address book. Duplicates will be skipped."),
            .finalStep(title: "Import of data completed!")
        ]
        
        vc.onClose = { [unowned self] in
            stop(success: false)
        }
        
        vc.onStart = { [unowned self] in
            selectFile()
        }
        
        show(vc)
    }
    
    func selectFile() {
        let vc = SelectDataFileViewController(nibName: nil, bundle: nil)
        vc.completion = { [unowned self] url in
            enterPassword(url)
        }
        show(vc)
    }
    
    func enterPassword(_ fileURL: URL) {
        let vc = CreateExportPasswordViewController(nibName: nil, bundle: nil)
        vc.title = "Enter password"
        vc.placeholder = "Enter password"
        vc.prompt = "Enter the password for the selected data file."
        vc.completion = { [unowned self] password in
            importData(fileURL, password)
        }
        show(vc)
    }
    
    func importData(_ fileURL: URL, _ password: String) {
        let vc = ImportInProgressViewController(nibName: nil, bundle: nil)
        vc.userPassword = password
        vc.fileURL = fileURL
        vc.completion = { [weak self] logs in
            self?.results(logs)
        }
        show(vc)
    }
    
    func results(_ logs: [String]) {
        if logs.isEmpty {
            let vc = SuccessViewController(
                titleText: "Import completed",
                bodyText: "Data import was successful.",
                primaryAction: "Done",
                secondaryAction: nil
            )
            vc.reenablesNavBar = false
            vc.setTrackingData(trackingEvent: .screenImportSuccess)
            
            vc.onDone = { [weak self] _ in
                self?.stop(success: true)
            }
            
            show(vc)
        } else {
            let vc = ErrorViewController(nibName: nil, bundle: nil)
            vc.imageName = "checkmark.circle.trianglebadge.exclamationmark"
            vc.titleText = "Import completed"
            vc.bodyText = "Some issues encountered during the import:"
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
