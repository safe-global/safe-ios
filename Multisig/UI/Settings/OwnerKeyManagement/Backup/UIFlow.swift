//
//  UIFlow.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 18.05.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

//
// Rationale for implementing UI navigation with a "flow", "factory", and separate view controllers.
//
// I want view controllers to be usable in different contexts --> isolate them
// I want to create view controllers with parameters in different flows --> use factory pattern
// I want the whole flow to be defined in one place --> create an object for that ('flow')
// I want the flow to be integratable into existing navigation stack --> pass the navigation controller to work with
// I want the flow to be stand-alone when opened from different places in the app --> create a navigation controller for the standalone case
// I want to have variations in the flows based on where it should be opened or based on the passed in parameters --> sub-class or enum/bool flags. If more variations can be added in the future, then it is better to subclass.
//
class UIFlow: NSObject {

    weak var presenter: UIViewController!
    var navigationController: UINavigationController!

    var completion: (_ success: Bool) -> Void

    internal init(completion: @escaping (_ success: Bool) -> Void) {
        self.completion = completion
    }

    func modal(from vc: UIViewController, dismissableOnSwipe: Bool = true) {
        let nav = CancellableNavigationController()
        nav.dismissableOnSwipe = dismissableOnSwipe
        nav.onCancel = { [unowned self] in
            stop(success: false)
        }
        navigationController = nav

        start()

        guard let rootVC = navigationController.viewControllers.first else {
            // nothing to present, exit
            return
        }
        ViewControllerFactory.addCloseButton(rootVC)

        presenter = vc

        if let presentedViewController = presenter.presentedViewController {
            presentedViewController.dismiss(animated: true) { [weak self] in
                self?.presenter.present(nav, animated: true)
                // the actual presenting view controller might be different from the `presenter`
                self?.presenter = nav.presentingViewController
            }
        } else {
            presenter.present(nav, animated: true)
            // the actual presenting view controller might be different from the `presenter`
            presenter = nav.presentingViewController
        }
    }

    func push(from vc: UIViewController) {
        navigationController = vc.navigationController!
        start()
    }

    func push(flow: UIFlow) {
        flow.navigationController = navigationController
        flow.start()
    }

    func start() {
        // to override
    }

    func stop(success: Bool) {
        if let presenter = presenter, presenter.presentedViewController != nil {
            presenter.dismiss(animated: true) { [unowned self] in
                completion(success)
            }
        } else {
            completion(success)
        }
    }

    func show(_ vc: UIViewController, animated: Bool = true, crossDissolve: Bool = false) {
        if navigationController.viewControllers.isEmpty {
            navigationController.viewControllers = [vc]
        } else if animated {
            if crossDissolve {
                let transition: CATransition = CATransition()
                transition.duration = 0.3
                transition.type = CATransitionType.fade
                navigationController.view.layer.add(transition, forKey: nil)
            }
            navigationController.pushViewController(vc, animated: !crossDissolve)
        } else {
            navigationController.pushViewController(vc, animated: false)
        }
    }
}

extension UIViewController {
    func present(flow: UIFlow, dismissableOnSwipe: Bool = true) {
        flow.modal(from: self, dismissableOnSwipe: dismissableOnSwipe)
    }

    func push(flow: UIFlow) {
        flow.push(from: self)
    }
}
