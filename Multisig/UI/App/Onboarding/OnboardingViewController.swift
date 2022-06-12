//
//  OnboardingViewController.swift
//  Multisig
//
//  Created by Moaaz on 6/7/22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class OnboardingViewController: UIViewController {

    @IBOutlet private weak var loadSafeButton: UIButton!
    @IBOutlet private weak var createSafeButton: UIButton!
    @IBOutlet private weak var demoButton: UIButton!
    @IBOutlet private weak var completelyNewLabel: UILabel!
    @IBOutlet private weak var skipButton: UIButton!
    @IBOutlet private weak var actionsContainerView: UIStackView!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var collectionView: UICollectionView!

    private let steps: [OnboardingStep] = [OnboardingStep(title: "The world of Web3 in your pocket",
                                                          description: (text: "Use the most popular Ethereum-compatible networks, connect to dApps, get transaction notifications and more.", highlightedText: "connect to dApps"),
                                                          image: UIImage(named: "ico-onboarding-1")!,
                                                          backgroundImage: UIImage(named: "ico-onboarding-background-1")!),
                                           OnboardingStep(title: "Stay in control of your funds",
                                                          description: (text: "Define how you manage digital assets and who gets authorized access to your crypto. Use multiple signer keys for better security.", highlightedText: "Use multiple signer keys"),
                                                          image: UIImage(named: "ico-onboarding-2")!,
                                                          backgroundImage: UIImage(named: "ico-onboarding-background-2")!),
                                           OnboardingStep(title: "Enjoy stealth security from Multi-signature",
                                                                  description: (text:"About $107B worth of digital assets are already securely stored by individuals and teams using Gnosis Safe.", highlightedText: "$107B worth of digital assets"),
                                                          image: UIImage(named: "ico-onboarding-3")!,
                                                          backgroundImage: UIImage(named: "ico-onboarding-background-3")!)
    ]

    private var completion: () -> () = { }

    convenience init(completion: @escaping () -> ()) {
        self.init()
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        completelyNewLabel.setStyle(.secondary)
        loadSafeButton.setText("Add existing Safe", .bordered)
        createSafeButton.setText("Create new Safe", .filled)
        demoButton.setText("Explore Demo", .primary)
        skipButton.setText("Skip", .primary)
        let nib = UINib(nibName: OnboardingStepCollectionViewCell.identifier, bundle: Bundle(for: OnboardingStepCollectionViewCell.self))
        collectionView.register(nib, forCellWithReuseIdentifier: OnboardingStepCollectionViewCell.identifier)

        collectionView.delegate = self
        collectionView.dataSource = self

        pageControl.numberOfPages = self.steps.count
        actionsContainerView.isHidden = true
    }

    @IBAction private func didTapLoadSafe(_ sender: Any) {
        Tracker.trackEvent(.addSafeFromOnboarding)
        let selectNetworkVC = SelectNetworkViewController()
        selectNetworkVC.screenTitle = "Load Gnosis Safe"
        selectNetworkVC.descriptionText = "Select network on which your Safe was created:"
        selectNetworkVC.completion = { [unowned selectNetworkVC, weak self] chain  in
            let vc = EnterSafeAddressViewController()
            vc.chain = chain
            let ribbon = RibbonViewController(rootViewController: vc)
            ribbon.chain = vc.chain
            vc.completion = {
                selectNetworkVC.dismiss(animated: true, completion: nil)
                self?.completion()
            }
            selectNetworkVC.show(ribbon, sender: selectNetworkVC)
        }
        let vc = ViewControllerFactory.modal(viewController: selectNetworkVC)
        present(vc, animated: true)
    }

    @IBAction private func didTapCreateSafe(_ sender: Any) {
        Tracker.trackEvent(.createSafeFromOnboarding)
        let instructionsVC = CreateSafeInstructionsViewController()
        instructionsVC.onClose = { [unowned instructionsVC, weak self] in
            instructionsVC.dismiss(animated: true, completion: nil)
            self?.completion()
        }
        let vc = ViewControllerFactory.modal(viewController: instructionsVC)
        present(vc, animated: true)
    }

    @IBAction private func didTapTryDemo(_ sender: Any) {
        let chain = Chain.mainnetChain()

        let demoAddress: Address = Address(exactly: Safe.demoAddress)
        let demoName = "Demo Safe"
        let safeVersion = "1.1.1"
        Safe.create(address: demoAddress.checksummed, version: safeVersion, name: demoName, chain: chain)

        App.shared.notificationHandler.safeAdded(address: demoAddress)
        completion()
        Tracker.trackEvent(.tryDemo)
    }

    @IBAction private func skipButtonTouched(_ sender: Any) {
        collectionView.scrollToItem(at: IndexPath(item: steps.count - 1, section: 0),
                                    at: .centeredHorizontally,
                                    animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { [weak self] in
            self?.bindCurrentStep()
        }
    }

    @IBAction func pageChanged(_ sender: Any) {
        let pc = sender as! UIPageControl

        collectionView.scrollToItem(at: IndexPath(item: pc.currentPage, section: 0),
                                        at: .centeredHorizontally, animated: true)
        bindCurrentStep()
    }

    private func bindCurrentStep() {
        pageControl.currentPage = Int(collectionView.contentOffset.x) / Int(collectionView.frame.width)

        
        UIView.transition(with: actionsContainerView, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            guard let self = self else { return }
            self.actionsContainerView.isHidden = self.pageControl.currentPage != self.pageControl.numberOfPages - 1
          })

        UIView.transition(with: skipButton, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            guard let self = self else { return }
            self.skipButton.isHidden = !self.actionsContainerView.isHidden
          })
    }
}

extension OnboardingViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return steps.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: OnboardingStepCollectionViewCell.identifier,
                                                      for: indexPath) as! OnboardingStepCollectionViewCell
        cell.configure(step: steps[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.collectionView.frame.width, height: self.collectionView.frame.height)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        bindCurrentStep()
    }
}
