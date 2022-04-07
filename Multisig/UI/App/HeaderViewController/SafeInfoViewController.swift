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
        let viewController = UIHostingController(rootView: view)
        viewController.view.backgroundColor = .backgroundSecondary
        viewControllers = [viewController]

        // Set explicit constraints instead of the autoresizing because otherwise the
        // card content view is not resizing with resizing of the SwiftUI content.
        viewController.view.translatesAutoresizingMaskIntoConstraints = false

        displayChild(at: 0, in: cardContentView)

        NSLayoutConstraint.activate([
            cardContentView.heightAnchor.constraint(equalTo: viewController.view.heightAnchor),
            cardContentView.widthAnchor.constraint(equalTo: viewController.view.widthAnchor)
        ])
        cardContentView.setNeedsUpdateConstraints()
    }

    @IBAction private func didTapClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
