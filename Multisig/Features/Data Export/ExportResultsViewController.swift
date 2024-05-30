//
//  ExportResultsViewController.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 29.05.24.
//  Copyright © 2024 Gnosis Ltd. All rights reserved.
//

import UIKit

class ExportResultsViewController: UIViewController {
    
    var result: (file: SecuredDataFile, key: Data)?
    var logs: [String] = []
    var date = Date()
    var exportID = ProcessInfo().globallyUniqueString
    
    var completion: (() -> Void)?
    
    @IBOutlet weak var logsTextView: UITextView!
    @IBOutlet weak var bodyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        if logs.isEmpty {
            logsTextView.text = "No errors"
        } else {
            logsTextView.text = logs.joined(separator: "\n")
        }
    }

    @IBAction func saveFile() {
        guard let result = result else {
            return
        }
        
        do {
            let data = try JSONEncoder().encode(result.file)
            let temporaryDirectoryURL = FileManager.default.temporaryDirectory
            
            let currentDate = date.formatted(Date.ISO8601FormatStyle())
            let filebase =  exportID + " " + currentDate + " Wallet App Data"
            let fileext = "safedata"
            let filename = filebase + "." + fileext
            
            let temporaryFileURL = temporaryDirectoryURL.appendingPathComponent(filename)
            
            try data.write(to: temporaryFileURL)
            
            let shareVC = UIActivityViewController(activityItems: [temporaryFileURL], applicationActivities: nil)
            
            shareVC.completionWithItemsHandler = { _, _, _, _ in
                do {
                    try FileManager.default.removeItem(at: temporaryFileURL)
                } catch {
                    LogService.shared.error("Failed to remove file: \(error)")
                }
            }
            
            present(shareVC, animated: true)
            
        } catch {
            LogService.shared.error("Failed to export file: \(error)")
        }
    }
    
    @IBAction func copyPassword() {
        guard let result = result else {
            return
        }
        
        let password = result.key.base64EncodedString()
        
        Pasteboard.string = password
        
        App.shared.snackbar.show(message: "Password copied to clipboard. Save it in a secure place.")
    }
    
    @IBAction func done() {
        completion?()
    }
}
