//
//  AssetsViewController.swift
//  Multisig
//
//  Created by Vitaly Katz on 15.12.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AssetsViewController: ContainerViewController {

    @IBOutlet private weak var totalBalanceView: TotalBalanceView!
    @IBOutlet private weak var contentView: UIView!
    
    private var balances: [TokenBalance]?
    
    private var safe: Safe?
    let segmentVC = SegmentViewController(namedClass: nil)

    private var relayOnboardingFlow: RelayOnboardingFlow? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        segmentVC.segmentItems = [
            SegmentBarItem(image: UIImage(named: "ico-coins")!, title: "Coins"),
            SegmentBarItem(image: UIImage(named: "ico-collectibles")!, title: "Collectibles")
        ]
        segmentVC.viewControllers = [
            BalancesViewController(),
            CollectiblesViewController()
        ]
        segmentVC.selectedIndex = 0
        
        viewControllers.append(segmentVC)
        
        displayChild(at: 0, in: contentView)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(balanceLoading),
            name: .balanceLoading,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateBalances),
            name: .balanceUpdated,
            object: nil)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(selectedSafeChangedReceived),
            name: .selectedSafeChanged,
            object: nil)

        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(selectedSafeUpdatedReceived),
            name: .selectedSafeUpdated,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(selectionChanged),
            name: .selectedSafeChanged,
            object: nil)
        
        totalBalanceView.onReceivedClicked = { [weak self] in
            let vc = SafeInfoViewController()
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            self?.present(vc, animated: true, completion: nil)
            Tracker.trackEvent(.assetTransferReceiveClicked)
        }
        
        totalBalanceView.onSendClicked = { [weak self] in
            //check if safe has an owner imported
            guard let safe = self?.safe else { return }
            if safe.isReadOnly {
                let vc = AddOwnerFirstViewController()
                vc.onSuccess = { [weak self, unowned safe] in
                    if !safe.isReadOnly {
                        self?.showSelectAssetsViewController()
                    }
                    self?.dismiss(animated: true)
                }
                let navigationController = UINavigationController(rootViewController: vc)
                self?.present(navigationController, animated: true)
            } else {
                self?.showSelectAssetsViewController()
            }
            Tracker.trackEvent(.assetTransferSendClicked)
        }

        totalBalanceView.onBuyClicked = { [weak self] in
            guard let safe = try? Safe.getSelected() else {
                return
            }
            Tracker.trackEvent(.userBuy)
            let vc = ViewControllerFactory.selectTopUpAddress(safe: safe)

            self?.present(vc, animated: true)
        }

        totalBalanceView.tokenBanner.onClaim = { [unowned self] in
            guard let safe = try? Safe.getSelected() else {
                return
            }

            Tracker.trackEvent(.bannerSafeTokenClaim)
            claimTokenFlow = ClaimSafeTokenFlow(safe: safe) { [unowned self] _ in
                claimTokenFlow = nil
            }
            present(flow: claimTokenFlow)
        }
        totalBalanceView.tokenBanner.onClose = { [unowned self] in
            safeTokenBannerWasShown = true
            totalBalanceView.tokenBanner.isHidden = !shouldShowSafeTokenBanner
            Tracker.trackEvent(.bannerSafeTokenSkip)
        }

        totalBalanceView.relayInfoBanner.onOpen = { [unowned self] in
            // open article in V1
            // Educational series will be shown in V2 of the relayer
            openInSafari(App.configuration.help.relayerInfoURL)
            Tracker.trackEvent(.bannerRelayOpen)
        }
        totalBalanceView.relayInfoBanner.onClose = { [unowned self] in
            relayBannerWasShown = true
            totalBalanceView.relayInfoBanner.isHidden = !shouldShowRelayBanner
            Tracker.trackEvent(.bannerRelaySkip)
        }

        safe = try? Safe.getSelected()

        updateSafeOptions()
    }

    private var shouldShowRelayBanner: Bool {
        relayBannerWasShown != true && (safe?.chain?.isSupported(feature: .relayingMobile) ?? false)
    }

    private var relayBannerWasShown: Bool? {
        get { AppSettings.relayBannerWasShown }
        set { AppSettings.relayBannerWasShown = newValue }
    }

    private var claimTokenFlow: ClaimSafeTokenFlow!

    private var shouldShowSafeTokenBanner: Bool {
        // claim period has ended -> no need to show the banner
        return false
    }

    private var safeTokenBannerWasShown: Bool? {
        get { AppSettings.safeTokenBannerWasShown }
        set { AppSettings.safeTokenBannerWasShown = newValue }
    }

    private func showSelectAssetsViewController() {
        guard let balances = self.balances else { return }
        let selectAssetVC = SelectAssetViewController(balances: balances)
        let vc = ViewControllerFactory.modalWithRibbon(viewController: selectAssetVC)
        present(vc, animated: true)
    }
    
    @objc private func balanceLoading() {
        totalBalanceView.loading = true
    }
    
    @objc private func updateBalances(_ notification: Notification) {
        totalBalanceView.loading = false
        let userInfo = notification.userInfo
        totalBalanceView.amount = userInfo?["total"] as? String
        self.balances = userInfo?["balances"] as? [TokenBalance]
        totalBalanceView.sendEnabled = !(balances?.isEmpty ?? true)
    }
    
    @objc private func selectedSafeUpdatedReceived(notification: Notification) {
        self.safe = notification.object as? Safe
        updateSafeOptions()
    }

    @objc private func selectedSafeChangedReceived(notification: Notification) {
        self.safe = try? Safe.getSelected()
        updateSafeOptions()
    }

    private func updateSafeOptions() {
        totalBalanceView.tokenBanner.isHidden = !shouldShowSafeTokenBanner
        totalBalanceView.relayInfoBanner.isHidden = !shouldShowRelayBanner
        totalBalanceView.buyEnabled = safe?.chain?.isSupported(feature: .moonpay) ?? false
    }
    
    @objc private func selectionChanged(notification: Notification) {
        self.safe = try? Safe.getSelected()
    }
}
