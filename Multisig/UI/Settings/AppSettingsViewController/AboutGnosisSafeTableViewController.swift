//
//  AboutGnosisSafeTableViewController.swift
//  Multisig
//
//  Created by Vitaly Katz on 08.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit


class AboutGnosisSafeTableViewController: UITableViewController {
    
    var legal = App.configuration.legal
    
    enum Item {
        case terms(String)
        case privacyPolicy(String)
        case licenses(String)
        case rateTheApp(String)
    }
    
    private var items: [Item] = [
        .terms("Terms of use"),
        .privacyPolicy("Privacy policy"),
        .licenses("Licenses"),
        .rateTheApp("Rate the app")
    ]
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "About Safe{Wallet}"
        
        tableView.registerCell(BasicCell.self)
        
        tableView.backgroundColor = .backgroundPrimary
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = items[indexPath.row]
        
        switch item {
        case Item.terms(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
        case Item.privacyPolicy(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
        case Item.licenses(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
        case Item.rateTheApp(let name):
            return tableView.basicCell(name: name, indexPath: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        switch item {
        case Item.terms:
            showTerms()
    
        case Item.privacyPolicy:
            showPrivacyPolicy()

        case Item.licenses:
            showLicenses()

        case Item.rateTheApp:
            showRateTheApp()
        }
    }
    
    fileprivate func showTerms() {
        openInSafari(legal.termsURL)
        Tracker.trackEvent(.settingsTerms)
    }
    
    fileprivate func showPrivacyPolicy() {
        openInSafari(legal.privacyURL)
        Tracker.trackEvent(.settingsPrivacyPolicy)
    }
    
    fileprivate func showLicenses() {
        openInSafari(legal.licensesURL)
        Tracker.trackEvent(.settingsLicenses)
    }
    
    fileprivate func showRateTheApp() {
        let url = App.configuration.contact.appStoreReviewURL
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
        Tracker.trackEvent(.settingsRateApp)
    }
}

extension AboutGnosisSafeTableViewController: NavigationRouter {
    func canNavigate(to route: NavigationRoute) -> Bool {
        false
    }
    
    func routeFrom(from url: URL) -> NavigationRoute? {
        nil
    }
    
    func navigate(to route: NavigationRoute) {
        if route.path == NavigationRoute.terms().path {
            presentAfterDelay { [weak self] in
                self?.showTerms()
            }
        } else if route.path == NavigationRoute.privacy().path {
            presentAfterDelay { [weak self] in
                self?.showPrivacyPolicy()
            }
        } else if route.path == NavigationRoute.licenses().path {
            presentAfterDelay { [weak self] in
                self?.showLicenses()
            }
        }
    }
    
    // 500 milliseconds was chosen because it is enough time to
    // first dismiss existing controllers, and then show the 'about' screen and
    // a specific detail view controller.
    // Other way of synchronisation (completion block or a notification) would be too cumbersome to implement.
    private func presentAfterDelay(ms: Int = 500, task: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) { [weak self] in
            guard let self = self else { return }
            if self.presentedViewController != nil {
                self.dismiss(animated: false)
            }
            
            task()
        }
    }
}
