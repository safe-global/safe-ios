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
    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var actionsContainerView: UIStackView!
    @IBOutlet private weak var pageControl: UIPageControl!
    @IBOutlet private weak var collectionView: UICollectionView!
    
    private var createSafeFlow: CreateSafeFlow!
    private var addSafeFlow: AddSafeFlow!
    
    private let steps: [OnboardingStep] = [OnboardingStep(title: (text: "The world of Web3 in your pocket",
                                                                  highlightedText: "Web3"),
                                                          description: (text: "Use the most popular Ethereum-compatible networks, connect to dApps, get transaction notifications and more.",
                                                                        highlightedText: "connect to dApps"),
                                                          image: UIImage(named: "ico-onboarding-1")!,
                                                          trackingEvent: .screenOnboarding1),
                                           OnboardingStep(title: (text: "Stay in control of your funds",
                                                                  highlightedText: "in control"),
                                                          description: (text: "Define how you manage digital assets and who gets authorized access to your crypto. Use multiple signer keys for better security.",
                                                                        highlightedText: "multiple signer keys"),
                                                          image: UIImage(named: "ico-onboarding-2")!,
                                                          trackingEvent: .screenOnboarding2),
                                           OnboardingStep(title: (text: "Enjoy stealth security from Multi-signature",
                                                                  highlightedText: "Multi-signature"),
                                                          description: (text:"About $107B worth of digital assets are already securely stored by individuals and teams using Safe.",
                                                                        highlightedText: "$107B worth of digital assets"),
                                                          image: UIImage(named: "ico-onboarding-3")!,
                                                          trackingEvent: .screenOnboarding3)
    ]

    private var completion: () -> () = { }

    convenience init(completion: @escaping () -> ()) {
        self.init()
        self.completion = completion
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        completelyNewLabel.setStyle(.callout)
        loadSafeButton.setText("Load existing Safe Account", .bordered)
        createSafeButton.setText("Create new Safe Account", .filled)
        demoButton.setText("Explore Demo", .primary)
        skipButton.setText("Skip", .primary)
        let nib = UINib(nibName: OnboardingStepCollectionViewCell.identifier, bundle: Bundle(for: OnboardingStepCollectionViewCell.self))
        collectionView.register(nib, forCellWithReuseIdentifier: OnboardingStepCollectionViewCell.identifier)

        collectionView.delegate = self
        collectionView.dataSource = self

        pageControl.numberOfPages = self.steps.count
        actionsContainerView.isHidden = true
        bindCurrentStep(page: 0)
        overrideUserInterfaceStyle = .dark
    }

    @IBAction private func didTapLoadSafe(_ sender: Any) {
        Tracker.trackEvent(.addSafeFromOnboarding)
        addSafeFlow = AddSafeFlow(completion: { [weak self] _ in
            self?.addSafeFlow = nil
            self?.completion()
        })
        present(flow: addSafeFlow)
    }

    @IBAction private func didTapCreateSafe(_ sender: Any) {
        Tracker.trackEvent(.createSafeFromOnboarding)
        createSafeFlow = CreateSafeFlow(completion: { [weak self] _ in
            self?.createSafeFlow = nil
            self?.completion()
        })
        present(flow: createSafeFlow, dismissableOnSwipe: false)
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
        Tracker.trackEvent(.onboardingSkipped)
        let page = steps.count - 1
        collectionView.scrollToItem(at: IndexPath(item: page, section: 0),
                                    at: .centeredHorizontally,
                                    animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) { [weak self] in
            self?.bindCurrentStep(page: page)
        }
    }

    @IBAction func pageChanged(_ sender: Any) {
        let pc = sender as! UIPageControl
        collectionView.scrollToItem(at: IndexPath(item: pc.currentPage, section: 0),
                                        at: .centeredHorizontally, animated: true)
        bindCurrentStep(page: pc.currentPage)
    }

    private func bindCurrentStep(page: Int) {
        pageControl.currentPage = page

        UIView.transition(with: actionsContainerView, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            guard let self = self else { return }
            self.actionsContainerView.isHidden = page != self.pageControl.numberOfPages - 1
          })

        UIView.transition(with: skipButton, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            guard let self = self else { return }
            self.closeButton.isHidden = page != self.pageControl.numberOfPages - 1
          })

        UIView.transition(with: skipButton, duration: 0.4,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            guard let self = self else { return }
            self.skipButton.isHidden = page == self.pageControl.numberOfPages - 1
          })

        let step = steps[page]
        if let event = step.trackingEvent {
            Tracker.trackEvent(event)
        }
    }

    @IBAction func didTapClosed(_ sender: Any) {
        completion()
    }
}

extension OnboardingViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
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
        let page = Int(collectionView.contentOffset.x) / Int(collectionView.frame.width)
        bindCurrentStep(page: page)
    }
}
