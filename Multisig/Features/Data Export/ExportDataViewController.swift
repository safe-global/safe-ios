//
//  ExportDataViewController.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 29.05.24.
//  Copyright © 2024 Gnosis Ltd. All rights reserved.
//

import UIKit

class ExportDataViewController: UIViewController, PasscodeProtecting {
    
    var exportController = ImportExportDataController()
    
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var startButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Export Data"
    }

    @IBAction func startExport() {
        authenticate { [weak self] success in
            if success {
                self?.exportData()
            }
        }
    }
    
    func indicateStarted() {
        activityView.startAnimating()
        startButton.isEnabled = false
    }
    
    func indicateStopped() {
        activityView.stopAnimating()
        startButton.isEnabled = true
    }
    
    func exportData() {
        indicateStarted()
        
        Task { @MainActor in
            let result = await exportController.exportEncrypted()
            let logs = exportController.logs
            
            let resultsVC = ExportResultsViewController(nibName: nil, bundle: nil)
            resultsVC.result = result
            resultsVC.logs = logs
            
            let nav = ViewControllerFactory.modal(viewController: resultsVC)
            
            resultsVC.completion = { [weak self] in
                self?.dismiss(animated: true, completion: { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                })
            }
        
            indicateStopped()
            present(nav, animated: true)
        }
    }
}
