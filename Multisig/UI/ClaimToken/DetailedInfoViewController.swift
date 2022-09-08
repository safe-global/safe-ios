//
//  DetailedInfoViewController.swift
//  Multisig
//
//  Created by Mouaz on 9/7/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class DetailedInfoViewController: UIViewController {
    @IBOutlet weak var contentLabel: UILabel!
    private var titleText: String!
    private var text: String?
    private var attributedText: NSAttributedString?

    convenience init (title: String, text: String?, attributedText: NSAttributedString?) {
        self.init(namedClass: DetailedInfoViewController.self)
        self.titleText = title
        self.text = text
        self.attributedText = attributedText
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        contentLabel.setStyle(.secondary)
        title = titleText
        
        contentLabel.text = text
        if let attributedText = attributedText {
            contentLabel.attributedText = attributedText
        }
    }
}
