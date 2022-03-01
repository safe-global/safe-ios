//
//  MainTabBarViewController.swift
//  Multisig
//
//  Created by Moaaz on 3/25/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import Intercom
import WhatsNewKit

class MainTabBarViewController: UITabBarController {
    var onFirstAppear: (_ vc: MainTabBarViewController) -> Void = { _ in
    }

    private weak var transactionsSegementControl: SegmentViewController?
    private var appearsFirstTime: Bool = true

    // In-memory queue of incoming requests to present. Due to limitation of UIKit,
    // only one view controller can be presented at the same time.
    fileprivate var requestQueue: [WebConnectionRequest] = []
    fileprivate var debounceTimer: Timer?
    fileprivate var presentingRequest: Bool = false

    static fileprivate let ASSETS_TAB_INDEX = 0
    static fileprivate let BALANCES_SEGMENT_INDEX = 0
    static fileprivate let SETTINGS_TAB_INDEX = 3
    static fileprivate let APP_SETTINGS_SEGMENT_INDEX = 0

    lazy var balancesTabVC: BalancesUINavigationController = {
        balancesTabViewController()
    }()

    lazy var transactionsTabVC: UIViewController = {
        transactionsTabViewController()
    }()

    lazy var dappsTabVC: UIViewController = {
        dappsTabViewController()
    }()

    lazy var settingsTabVC: UIViewController = {
        settingsTabViewController()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        updateTabs()
        tabBar.barTintColor = .secondaryBackground

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showHistoryTransactions),
            name: .incommingTxNotificationReceived,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showQueuedTransactions),
            name: .queuedTxNotificationReceived,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConfirmTransactionNotificationReceived),
            name: .confirmationTxNotificationReceived,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInitiateTransactionNotificationReceived),
            name: .initiateTxNotificationReceived,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSafeCreated),
            name: .safeCreationUpdate,
            object: nil)

        WebConnectionController.shared.attach(observer: self)
    }

    deinit {
        WebConnectionController.shared.detach(observer: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard appearsFirstTime else {
            return
        }
        appearsFirstTime = false

        onFirstAppear(self)

        WhatsNewHandler().whatsNewViewController?.present(on: self)

        WebConnectionController.shared.reconnect()
    }

    private func balancesTabViewController() -> BalancesUINavigationController {
        
        let assetsVC = AssetsViewController()

        let noSafesVC = NoSafesViewController()
        let loadSafeViewController = LoadSafeViewController()
        loadSafeViewController.trackingEvent = .assetsNoSafe

        let deploySafeVC = SafeDeployingViewController()

        let ribbonVC = RibbonViewController(rootViewController: assetsVC)
        noSafesVC.hasSafeViewController = ribbonVC
        noSafesVC.noSafeViewController = loadSafeViewController

        noSafesVC.safeDepolyingViewContoller = ViewControllerFactory.ribbonWith(viewController: deploySafeVC)
        let tabRoot = HeaderViewController(rootViewController: noSafesVC)
        let balances = balancesTabViewController(
            root: tabRoot, title: "Assets", image: UIImage(named: "tab-icon-balances.pdf")!, tag: 0)
        balances.assetsViewController = assetsVC

        return balances
    }

    private func transactionsTabViewController() -> UIViewController {
        let queuedTransactionsViewController = QueuedTransactionsViewController()
        let historyTransactionsViewController = HistoryTransactionsViewController()

        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: UIImage(named: "ico-queued-transactions")!, title: "QUEUE"),
            SegmentBarItem(image: UIImage(named: "ico-history-transactions")!, title: "HISTORY")
        ]
        segmentVC.viewControllers = [
            queuedTransactionsViewController,
            historyTransactionsViewController
        ]
        segmentVC.selectedIndex = 0

        let noSafesVC = NoSafesViewController()
        let loadSafeViewController = LoadSafeViewController()
        let deploySafeVC = SafeDeployingViewController()

        loadSafeViewController.trackingEvent = .transactionsNoSafe
        let ribbonVC = RibbonViewController(rootViewController: segmentVC)
        noSafesVC.hasSafeViewController = ribbonVC
        noSafesVC.noSafeViewController = loadSafeViewController
        noSafesVC.safeDepolyingViewContoller = ViewControllerFactory.ribbonWith(viewController: deploySafeVC)

        let tabRoot = HeaderViewController(rootViewController: noSafesVC)
        transactionsSegementControl = segmentVC

        return tabViewController(
            root: tabRoot, title: "Transactions", image: UIImage(named: "tab-icon-transactions")!, tag: 1)
    }

    private func dappsTabViewController() -> UIViewController {
        let noSafesVC = NoSafesViewController()
        let loadSafeViewController = LoadSafeViewController()
        let deploySafeVC = SafeDeployingViewController()

        loadSafeViewController.trackingEvent = .dappsNoSafe
        noSafesVC.hasSafeViewController = RibbonViewController(rootViewController: DappsViewController())
        noSafesVC.noSafeViewController = loadSafeViewController
        noSafesVC.safeDepolyingViewContoller = ViewControllerFactory.ribbonWith(viewController: deploySafeVC)

        let tabRoot = HeaderViewController(rootViewController: noSafesVC)
        return tabViewController(root: tabRoot, title: "dApps", image: UIImage(named: "tab-icon-dapps")!, tag: 2)
    }

    private func settingsTabViewController() -> UIViewController {
        let noSafesVC = NoSafesViewController()
        let loadSafeViewController = LoadSafeViewController()
        let deploySafeVC = SafeDeployingViewController()

        loadSafeViewController.trackingEvent = .settingsSafeNoSafe
        noSafesVC.hasSafeViewController = SafeSettingsViewController()
        noSafesVC.noSafeViewController = loadSafeViewController
        noSafesVC.safeDepolyingViewContoller = deploySafeVC

        let appSettingsVC = AppSettingsViewController()

        let segmentVC = SegmentViewController(namedClass: nil)
        segmentVC.segmentItems = [
            SegmentBarItem(image: UIImage(named: "ico-app-settings")!, title: "App Settings"),
            SegmentBarItem(image: UIImage(named: "ico-safe-settings")!, title: "Safe Settings")
        ]
        segmentVC.viewControllers = [
            appSettingsVC,
            noSafesVC
        ]
        segmentVC.selectedIndex = Self.APP_SETTINGS_SEGMENT_INDEX
        let ribbonVC = RibbonViewController(rootViewController: segmentVC)
        
        let tabRoot = HeaderViewController(rootViewController: ribbonVC)
        let settingsTabVC = settingsTabViewController(root: tabRoot, title: "Settings", image: UIImage(named: "tab-icon-settings")!, tag: Self.SETTINGS_TAB_INDEX)
        settingsTabVC.segmentViewController = segmentVC
        settingsTabVC.appSettingsViewController = appSettingsVC
        return settingsTabVC
    }

    private func balancesTabViewController(root: UIViewController, title: String, image: UIImage, tag: Int) -> BalancesUINavigationController {
        let nav = BalancesUINavigationController(rootViewController: root)
        let tabItem = UITabBarItem(title: title, image: image, tag: tag)
        nav.tabBarItem = tabItem
        return nav
    }

    private func settingsTabViewController(root: UIViewController, title: String, image: UIImage, tag: Int) -> SettingsUINavigationController {
        let nav = SettingsUINavigationController(rootViewController: root)
        let tabItem = UITabBarItem(title: title, image: image, tag: tag)
        nav.tabBarItem = tabItem
        return nav
    }

    private func tabViewController(root: UIViewController, title: String, image: UIImage, tag: Int) -> UIViewController {
        let nav = UINavigationController(rootViewController: root)
        let tabItem = UITabBarItem(title: title, image: image, tag: tag)
        nav.tabBarItem = tabItem
        return nav
    }
    
    @objc private func handleInitiateTransactionNotificationReceived(_ notification: Notification) {
        if let transactionDetails = notification.userInfo?["transactionDetails"] as? SCGModels.TransactionDetails {
            showTransactionDetails(transactionDetails: transactionDetails)
        } else {
            showQueuedTransactions()
        }
    }

    @objc private func showQueuedTransactions() {
        selectedIndex = 1
        transactionsSegementControl?.selectedIndex = 0
    }

    @objc private func showHistoryTransactions() {
        selectedIndex = 1
        transactionsSegementControl?.selectedIndex = 1
    }
    
    @objc private func updateTabs() {
        viewControllers = [balancesTabVC, transactionsTabVC, dappsTabVC, settingsTabVC]        
    }

    @objc func handleConfirmTransactionNotificationReceived(_ notification: Notification) {
        guard let safeTxHash = App.shared.notificationHandler.transactionDetailsPayload else { return }
        App.shared.notificationHandler.transactionDetailsPayload = nil
        showTransactionDetails(safeTxHash: safeTxHash)
    }
    
    @objc private func handleSafeCreated(_ notification: Notification) {
        // get mode, txHash, and safe if creation successful from the notification
        if
            let status = notification.userInfo?["success"] as? Bool,
            let chain = notification.userInfo?["chain"] as? Chain,
            let safe = notification.userInfo?["safe"] as? Safe {
            
            let txHash = notification.userInfo?["txHash"] as? String
            
            var mode: SafeDeploymentFinishedViewController.Mode
            if status {
                // For debugging
                mode = .failure
            } else {
                mode = .failure
            }

            if mode == .failure || safe.isSelected {
                SafeDeploymentFinishedViewController.present(
                    presenter: self,
                    mode: mode,
                    chain: chain,
                    txHash: txHash,
                    safe: safe,
                    onClose: {
                        if mode == .failure {
                            Safe.remove(safe: safe)
                        }
                    },
                    onRetry: { [weak self] in
                        let createSafeVC = CreateSafeViewController()
                        createSafeVC.txHash = txHash
                        createSafeVC.chain = chain
                        createSafeVC.onClose = { [weak self] in
                            self?.dismiss(animated: true, completion: nil)
                        }
                        let vc = ViewControllerFactory.modal(viewController: createSafeVC)
                        self?.present(vc, animated: true)
                    })
            } else {
                SafeDeploymentNotificationController.sendNotification(safe: safe)
            }
        }
    }
    
    private func showTransactionDetails(safeTxHash: Data) {
        let vc = ViewControllerFactory.transactionDetailsViewController(safeTxHash: safeTxHash)
        present(vc, animated: true, completion: nil)
    }
    
    private func showTransactionDetails(transactionDetails: SCGModels.TransactionDetails) {
        let vc = ViewControllerFactory.transactionDetailsViewController(transaction: transactionDetails)
        present(vc, animated: true, completion: nil)
    }
}

extension MainTabBarViewController: NavigationRouter {
    func canNavigate(to route: NavigationRoute) -> Bool {
        if route.path.starts(with: "/settings/") {
            return true
        } else if route.path == NavigationRoute.showAssets().path {
            return true
        }

        return false
    }

    func navigate(to route: NavigationRoute) {
        if route.path.starts(with: "/settings/") {
            guard let settingsNav = settingsTabVC as? SettingsUINavigationController,
                  let segmentVC = settingsNav.segmentViewController,
                  let appSettingsVC = settingsNav.appSettingsViewController else {
                return
            }
            selectedIndex = Self.SETTINGS_TAB_INDEX
            segmentVC.selectedIndex = Self.APP_SETTINGS_SEGMENT_INDEX
            appSettingsVC.navigateAfterDelay(to: route)

        } else if route.path == NavigationRoute.showAssets().path {
            guard let assetsVC = balancesTabVC.assetsViewController,
                  !assetsVC.segmentVC.segmentItems.isEmpty else { return }
            selectedIndex = Self.ASSETS_TAB_INDEX
            assetsVC.segmentVC.selectedIndex = Self.BALANCES_SEGMENT_INDEX
        }
    }
}

class SettingsUINavigationController: UINavigationController {
    weak var segmentViewController: SegmentViewController?
    weak var appSettingsViewController: AppSettingsViewController?

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showBadge),
            name: NSNotification.Name.IntercomUnreadConversationCountDidChange,
            object: nil)

    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func showBadge() {
        let count = Intercom.unreadConversationCount()
        if count > 0 {
            tabBarItem.badgeValue = ""
            tabBarItem.badgeColor = UIColor.pending
        } else {
            tabBarItem.badgeValue = nil
        }
    }
}

class BalancesUINavigationController: UINavigationController {
    weak var assetsViewController: AssetsViewController?
}


extension MainTabBarViewController: WebConnectionRequestObserver {
    func didUpdate(request: WebConnectionRequest) {
        guard request.status == .pending else { return }
        requestQueue.append(request)
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false, block: { [weak self] _ in
            self?.presentRequests()
        })
    }

    /// Presents next request from the queue.
    /// The way how UIKit presentation works is that you can present only one
    /// screen at the same time, and you can't present another one during any presentation animation.
    /// That's why we queue the requests and open next from the queue when the current one is closed.
    func presentRequests() {
        guard !requestQueue.isEmpty && !presentingRequest else { return }
        let request = requestQueue.removeLast()

        presentingRequest = true
        let completion: () -> Void = { [weak self] in
            self?.presentingRequest = false
            self?.presentRequests()
        }

        switch request {
        case let signRequest as WebConnectionSignatureRequest:
            let vc = SignatureRequestViewController()
            present(controller: vc, request: signRequest, completion: completion)

        case let txRequest as WebConnectionSendTransactionRequest:
            let vc = SendTransactionRequestViewController()
            present(controller: vc, request: txRequest, completion: completion)

        default:
            presentingRequest = false
            presentRequests()
            break
        }
    }

    fileprivate func present<T, R>(controller: T, request: R, completion: @escaping () -> Void) where T: WebRequestViewController, T: UIViewController, T.Request == R, R: WebConnectionRequest {
        controller.request = request
        controller.controller = WebConnectionController.shared
        controller.connection = WebConnectionController.shared.connection(for: request)
        controller.onFinish = { [weak self] in
            self?.dismiss(animated: true, completion: completion)
        }
        let vc = ViewControllerFactory.modal(viewController: controller)
        present(vc, animated: true)
    }
}

protocol WebRequestViewController: AnyObject {
    associatedtype Request
    var request: Request! { get set }
    var controller: WebConnectionController! { get set }
    var connection: WebConnection! { get set }
    var onFinish: () -> Void { get set }
}

extension SignatureRequestViewController: WebRequestViewController {}

extension SendTransactionRequestViewController: WebRequestViewController {}
