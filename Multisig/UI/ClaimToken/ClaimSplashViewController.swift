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
    
    var completion: (_ eligible: Bool?) -> Void = { _ in }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ViewControllerFactory.removeNavigationBarBorder(self)
        
        titleLabel.isSkeletonable = true
        titleLabel.skeletonTextLineHeight = .relativeToFont
        reload()
    }
    
    func reload() {
        titleLabel.showSkeleton(delay: 0)
        
        _ = controller.allocations(address: safe.addressValue) { [weak self] result in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                do {
                    let allocations = try result.get()
                    if !allocations.isEmpty {
                        self.completion(true)
                    }
                } catch is GSError.EntityNotFound {
                    self.completion(false)
                } catch let error as DetailedLocalizedError {
                    // other error
                    App.shared.snackbar.show(error: error)
                    self.completion(nil)
                } catch {
                    App.shared.snackbar.show(message: "Failed to load data: \(error.localizedDescription)")
                    self.completion(nil)
                }
            }
        }
    }
    
}
