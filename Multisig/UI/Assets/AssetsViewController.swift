//
//  AssetsViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 21.09.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

class AssetsTabViewController: SegmentViewController, JPEGsViewControllerDelegate, BalancesViewControllerDelegate {

    let balancesController = BalancesViewController()
    let jpegsController = CollectiblesViewController()

    convenience init() {
        self.init(namedClass: SegmentViewController.self)

        segmentItems = []
        viewControllers = [
            balancesController,
            jpegsController
        ]

        jpegsController.delegate = self
        balancesController.delegate = self

        selectedIndex = 0

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didChangeSelectedSafe),
            name: .selectedSafeChanged,
            object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        selectSegment(at: 0)
    }

    @objc func didChangeSelectedSafe(notification: Notification) {
        self.segmentItems = []
        self.reloadSegmentBar()
        selectSegment(at: 0)
    }

    func balancesViewControllerDidStartReloading(_ controller: BalancesViewController) {
        if segmentItems.isEmpty {
            loadJPEGsAsync { [weak self] isEmptyOrError in
                guard let self = self else { return }

                if isEmptyOrError {
                    // do nothing
                } else {
                    DispatchQueue.main.async {
                        self.segmentItems = [
                            SegmentBarItem(image: UIImage(named: "ico-coins")!, title: "Coins"),
                            SegmentBarItem(image: UIImage(named: "ico-collectibles")!, title: "JPEGs")
                        ]
                        self.reloadSegmentBar()
                        self.selectSegment(at: 0)
                    }
                }
            }
        }
    }

    func jpegsViewControllerDidFinishLoading(_ controller: CollectiblesViewController) {
        if controller.isEmpty || !controller.dataErrorView.isHidden {
            self.segmentItems = []
            self.reloadSegmentBar()
            self.selectSegment(at: 0)
        } else {
            // do nothing
        }
    }

    func loadJPEGsAsync(_ completion: @escaping (_ isEmptyOrError: Bool) -> Void) {
        let IS_ERROR = true
        let IS_EMPTY = true
        let HAS_CONTENT = false

        do {
            guard let safe = try Safe.getSelected() else {
                // nothing selected - assets won't be visible, so do nothing.
                return
            }
            let address = safe.addressValue
            let chainId = safe.chain!.id!

            _ = jpegsController.clientGatewayService.asyncCollectibles(
                safeAddress: address,
                chainId: chainId
            ) { result in

                guard
                    let maybeSameSafe = (try? Safe.getSelected()),
                    maybeSameSafe.addressValue == address,
                    maybeSameSafe.chain?.id == chainId
                else {
                    // too late, the selected safe has changed. Disregard this completion.
                    return
                }

                switch result {
                case .failure:
                    completion(IS_ERROR)
                case .success(let collectibles):
                    if collectibles.isEmpty {
                        completion(IS_EMPTY)
                    } else {
                        completion(HAS_CONTENT)
                    }
                }
            }
        } catch {
            completion(IS_ERROR)
        }
    }
}
