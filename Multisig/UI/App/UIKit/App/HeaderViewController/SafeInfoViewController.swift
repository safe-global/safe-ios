//
//  SafeInfoViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 16.11.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit
import SwiftUI

class SafeInfoViewController: ContainerViewController {
    @IBOutlet private weak var cardContentView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let view = SafeInfoView()
            .environment(\.managedObjectContext, App.shared.coreDataStack.viewContext)
        viewControllers = [UIHostingController(rootView: view)]
        displayChild(at: 0, in: cardContentView)
    }

    @IBAction private func didTapClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
