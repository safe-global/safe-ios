//
//  WhatIsSafeViewController.swift
//  Multisig
//
//  Created by Dirk Jäckel on 02.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class WhatIsSafeViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    @IBOutlet weak var pageControl: UIPageControl!


    private let screens: [TutorialScreen] = [
        TutorialScreen(title: "What is the safe?",
                description: "Safe is critical infrastructure for web3.  It is a programmable account standard that enables secure management of digital assets, data and identity.\nWith this token launch, Safe is now a community-driven ownership platform."
        ),
        TutorialScreen(title: "Distribution",
                description: "Safe Tokens will be distributed to stakeholders of the ecosystem interested in shaping the future of Safe and smart-contract accounts."
        ),
        TutorialScreen(title: "What exactly is Safe token and what does it govern?",
                description: "$SAFE is an ERC-20 governance token that stewards infrastructure components of the Safe ecosystem, including:"
        ),
        TutorialScreen(title: "Navigating SafeDAO",
                description: "SafeDAO aims to foster a vibrant ecosystem of applications and wallets leveraging Safe smart contract accounts. This will be achieved through data-backed discussions, grants, ecosystem investments, as well as providing developer tools and infrastructure."
        )
    ]

    override func viewDidLoad() {
        super.viewDidLoad()


        ViewControllerFactory.addCloseButton(self)
        ViewControllerFactory.makeTransparentNavigationBar(self)

        let nib = UINib(nibName: TutorialScreenCollectionViewCell.identifier, bundle: Bundle(for: TutorialScreenCollectionViewCell.self))
        collectionView.register(nib, forCellWithReuseIdentifier: TutorialScreenCollectionViewCell.identifier)

        collectionView.delegate = self
        collectionView.dataSource = self

        pageControl.numberOfPages = self.screens.count
        print("Number of pages: \(self.screens.count)")
        bindCurrentScreen(page: 0)

        //TODO: Show 1/4 in the top corner
        //ViewControllerFactory. // TODO show step 1/4 in the top right corner

    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    private func bindCurrentScreen(page: Int) {
        pageControl.currentPage = page

//        UIView.transition(with: actionsContainerView, duration: 0.4,
//                options: .transitionCrossDissolve,
//                animations: { [weak self] in
//                    guard let self = self else { return }
//                    self.actionsContainerView.isHidden = page != self.pageControl.numberOfPages - 1
//                })

//        UIView.transition(with: skipButton, duration: 0.4,
//                options: .transitionCrossDissolve,
//                animations: { [weak self] in
//                    guard let self = self else { return }
//                    self.closeButton.isHidden = page != self.pageControl.numberOfPages - 1
//                })
//
//        UIView.transition(with: skipButton, duration: 0.4,
//                options: .transitionCrossDissolve,
//                animations: { [weak self] in
//                    guard let self = self else { return }
//                    self.skipButton.isHidden = page == self.pageControl.numberOfPages - 1
//                })

        // TODO tracking
//        let screen = screens[page]
//        if let event = screen.trackingEvent {
//            Tracker.trackEvent(event)
//        }
    }

    @IBAction func pageChanged(_ sender: Any) {
        let pc = sender as! UIPageControl
        print("pageChanged: pc.currentPage: \(pc.currentPage)")
        collectionView.scrollToItem(at: IndexPath(item: pc.currentPage, section: 0), at: .centeredHorizontally, animated: true)
        bindCurrentScreen(page: pc.currentPage)
    }
}

extension WhatIsSafeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    //UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return screens.count
    }

    // UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TutorialScreenCollectionViewCell.identifier,
                for: indexPath) as! TutorialScreenCollectionViewCell
        cell.configure(step: screens[indexPath.row])
        return cell
    }

    // UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.width, height: self.collectionView.frame.height)
    }

    // UIScrollViewDelegate
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(collectionView.contentOffset.x) / Int(collectionView.frame.width)
        bindCurrentScreen(page: page)
    }
}
