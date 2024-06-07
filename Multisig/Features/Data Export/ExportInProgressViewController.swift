//
//  ExportInProgressViewController.swift
//  Multisig
//
//  Created by Dmitrii Bespalov on 05.06.24.
//  Copyright © 2024 Core Contributors GmbH. All rights reserved.
//

import UIKit

class ExportInProgressViewController: UIViewController {
    
    var userPassword: String!
    var completion: (_ result: (tempFileURL: URL?, logs: [String])) -> Void = { _ in }
    
    private var didExport: Bool = false
    private var exportController = ImportExportDataController()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Exporting data..."
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        guard !didExport else { return }
        didExport = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: { [weak self] in
            self?.exportData()
        })
    }
    
    func exportData() {
        Task { @MainActor in
            guard let userPassword = userPassword else {
                return
            }
            let tempFileURL = await exportController.exportToTemporaryFile(key: userPassword)
            let isOnScreen = viewIfLoaded?.window != nil
            guard isOnScreen else {
                return
            }
            completion((tempFileURL, exportController.logs))
        }
    }

}
