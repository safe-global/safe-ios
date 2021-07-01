//
//  HeaderViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

/// Header bar will adapt to the devices size
final class HeaderViewController: ContainerViewController {
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var headerBar: UIView!
    @IBOutlet private weak var ribbonView: RibbonView!
    @IBOutlet private weak var barShadowView: UIImageView!
    @IBOutlet private weak var safeBarView: SafeBarView!
    @IBOutlet private weak var noSafeBarView: NoSafeBarView!
    @IBOutlet private weak var switchSafeButton: UIButton!
    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var headerBarHeightConstraint: NSLayoutConstraint!

    private var rootViewController: UIViewController?
    private var currentDataTask: URLSessionTask?

    var clientGatewayService = App.shared.clientGatewayService
    var notificationCenter = NotificationCenter.default

    convenience init(rootViewController: UIViewController) {
        self.init(namedClass: nil)
        self.rootViewController = rootViewController
        viewControllers = [rootViewController]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        safeBarView.addTarget(self, action: #selector(didTapSafeBarView(_:)), for: .touchUpInside)
        reloadHeaderBar()
        displayRootController()
        addObservers()
        headerBarHeightConstraint.constant = ScreenMetrics.safeHeaderHeight
        reloadSafeData()
    }

    private func addObservers() {
        let updateNotifications: [NSNotification.Name] = [
            .selectedSafeChanged, .selectedSafeUpdated, .ownerKeyImported, .ownerKeyRemoved
        ]
        for name in updateNotifications {
            notificationCenter.addObserver(self,
                                           selector: #selector(didReceiveUpdateNotification(_:)),
                                           name: name,
                                           object: nil)
        }
        notificationCenter.addObserver(
            self,
            selector: #selector(reloadSafeData),
            name: UIScene.willEnterForegroundNotification,
            object: nil)

        notificationCenter.addObserver(
            self,
            selector: #selector(reloadHeaderBar),
            name: .networkInfoChanged,
            object: nil)
    }

    private func displayRootController() {
        assert(!viewControllers.isEmpty)
        displayChild(at: 0, in: contentView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    @IBAction private func didTapSwitchSafe(_ sender: Any) {
        let switchSafesVC = SwitchSafesViewController()
        let nav = UINavigationController(rootViewController: switchSafesVC)
        present(nav, animated: true)
    }

    @objc private func didTapSafeBarView(_ sender: Any) {
        let vc = SafeInfoViewController(nibName: nil, bundle: nil)
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)
    }

    @objc private func didReceiveUpdateNotification(_ notification: Notification) {
        if notification.name == .selectedSafeChanged {
            reloadSafeData()
        }
        reloadHeaderBar()
    }

    @objc private func reloadHeaderBar() {
        do {
            let selectedSafe = try Safe.getSelected()
            let hasSafe = selectedSafe != nil
            safeBarView.isHidden = !hasSafe
            switchSafeButton.isHidden = !hasSafe
            noSafeBarView.isHidden = hasSafe

            if let safe = selectedSafe {
                safeBarView.setAddress(safe.addressValue)
                safeBarView.setName(safe.displayName)
                safeBarView.setReadOnly(safe.isReadOnly)
            }

            if let network = selectedSafe?.network,
               let name = network.chainName,
               let textColor = network.textColor,
               let backgroundColor = network.backgroundColor {
                ribbonView.text = name
                ribbonView.textColor = textColor
                ribbonView.backgroundColor = backgroundColor
                ribbonView.isHidden = false
            } else {
                ribbonView.isHidden = true
            }
        } catch {
            App.shared.snackbar.show(
                error: GSError.error(description: "Failed to update selected safe", error: error))
        }
    }

    @objc private func reloadSafeData() {
        currentDataTask?.cancel()
        do {
            guard let safe = try Safe.getSelected() else { return }
            currentDataTask = clientGatewayService.asyncSafeInfo(safeAddress: safe.addressValue,
                                                                 networkId: safe.network!.id) { [weak self] result in
                DispatchQueue.main.async { [weak self] in
                    switch result {
                    case .failure(let error):
                        // ignore cancellation error due to cancelling the
                        // currently running task.
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                            (error as NSError).domain == NSURLErrorDomain {
                            return
                        }
                        LogService.shared.error("Failed to reload safe info: \(error)")
                    case .success(let safeInfo):
                        safe.update(from: safeInfo)
                        self?.reloadHeaderBar()
                    }
                }
            }
        } catch {
            LogService.shared.error("Failed to reload safe info: \(error)")
        }
    }
}

extension Network {
    var textColor: UIColor? {
        theme?.textColor.flatMap(UIColor.init(hex:))
    }
    var backgroundColor: UIColor? {
        theme?.backgroundColor.flatMap(UIColor.init(hex:))
    }
}
