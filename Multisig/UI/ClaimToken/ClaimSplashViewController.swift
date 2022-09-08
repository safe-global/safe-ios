//
//  ClaimSplashViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 05.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class ClaimSplashViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    
    var safe: Safe!
    var controller: ClaimingAppController!
    
    var completion: (_ claimData: ClaimingAppController.ClaimingData?) -> Void = { _ in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.removeNavigationBarBorder(self)
        
        titleLabel.isSkeletonable = true
        titleLabel.skeletonTextLineHeight = .relativeToFont
        titleLabel.showAnimatedSkeleton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }
    
    func reload() {
        controller.asyncFetchData(account: safe.addressValue) { [weak self] result in
            guard let `self` = self else { return }
            do {
                let data = try result.get()
                self.completion(data)
            } catch {
                self.completion(nil)
            }
        }
    }
    
}
