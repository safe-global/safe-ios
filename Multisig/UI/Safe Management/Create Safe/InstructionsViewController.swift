//
//  InstructionsViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 22.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class InstructionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var onClose: () -> Void = {}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "How does it work?"
        
        button.setText("OK, Let’s start", .filled)
    }
    
    override func closeModal() {
        onClose()
    }
    
    @IBAction func didTapButton(_ sender: Any) {
        let createSafeVC = CreateSafeViewController()
        createSafeVC.onClose = onClose
        show(createSafeVC, sender: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }
}
