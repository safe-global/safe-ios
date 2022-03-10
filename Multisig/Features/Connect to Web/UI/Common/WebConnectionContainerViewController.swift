//
//  WebConnectionContainerViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.02.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import Foundation
import UIKit

class WebConnectionContainerViewController: ContainerViewController, UIAdaptivePresentationControllerDelegate, ActionPanelViewDelegate {
    @IBOutlet weak var ribbonView: RibbonView!
    @IBOutlet weak var headerView: ChooseOwnerDetailHeaderView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var actionPanelView: ActionPanelView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var onFinish: () -> Void = { }

    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.style = .large
        actionPanelView.delegate = self
    }

    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        // needed to react to the "swipe down" to close the modal screen
        parent?.presentationController?.delegate = self
    }

    override func closeModal() {
        didCancel()
    }

    // Called when user swipes down the modal screen
    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        didCancel()
    }

    func didCancel() {
        // to override
    }

    func didReject() {
        // to override
    }

    func didConfirm() {
        // to override
    }

}
