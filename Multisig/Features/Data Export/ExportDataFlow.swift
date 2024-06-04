//
//  ExportDataFlow.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 03.06.24.
//  Copyright © 2024 Gnosis Ltd. All rights reserved.
//

import Foundation

class ExportDataFlow: UIFlow {
    
    override func start() {
        
    }
    
    func instructions() {
        let vc = CommonInstructionsViewController()
        vc.title = "Export Data"
        
        vc.steps = [
            .header,
            .step(number: "1", title: "Create a file password", description: "Enter a strong password for locking the export file."),
            .step(number: "2", title: "Export the data", description: "Data includes the owner keys, safes and address book in an encrypted file format."),
            .step(number: "3", title: "Save the data file", description: "Store the export file in Files on your device or a secure location of your choice.")
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
        
    }
    
    func repeatPassword() {
        
    }
    
    func exportData() {
        
    }
    
    func saveExportedData() {
        
    }
}

class CommonInstructionsViewController: InstructionsViewController {
    var onStart: (() -> Void)?
    
    convenience init() {
        self.init(namedClass: InstructionsViewController.self)
    }
    
    override func didTapButton(_ sender: Any) {
        onStart?()
    }
}
