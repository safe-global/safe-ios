//
//  AllocationBoxCell.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 01.09.22.
//  Copyright © 2022 Gnosis Ltd. All rights reserved.
//

import UIKit

class AllocationBoxCell: UITableViewCell {
    @IBOutlet private weak var boxView: StyledView!
    @IBOutlet private weak var contentStack: UIStackView!

    @IBOutlet private weak var backgroundImage: UIImageView!
    @IBOutlet private weak var headerStack: UIStackView!
    @IBOutlet private weak var headerLabel: UILabel!
    @IBOutlet private weak var headerButton: InfoButton!

    @IBOutlet private weak var bodyStack: UIStackView!
    @IBOutlet private weak var titleStack: UIStackView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleButton: InfoButton!

    @IBOutlet private weak var valueLabel: UILabel!

    @IBOutlet private weak var boxOuterTrailing: NSLayoutConstraint!
    @IBOutlet private weak var boxOuterLeading: NSLayoutConstraint!
    @IBOutlet private weak var boxOuterTop: NSLayoutConstraint!
    @IBOutlet private weak var boxOuterBottom: NSLayoutConstraint!

    @IBOutlet private weak var boxInnerTop: NSLayoutConstraint!
    @IBOutlet private weak var boxInnerBottom: NSLayoutConstraint!
    @IBOutlet private weak var boxInnerTrailing: NSLayoutConstraint!
    @IBOutlet private weak var boxInnerLeading: NSLayoutConstraint!

    enum Style {
        case darkGuardian
        case darkUser
        case lightGuardian
        case lightUser
    }

    var style: Style = .darkGuardian {
        didSet {
            updateStyle()
        }
    }

    var boxOuterSpacing: UIEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
    var boxInnerSpacing: UIEdgeInsets = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)

    var contentVerticalSpacing: CGFloat = 16
    var buttonHorizontalSpacing: CGFloat = 8
    var bodyVerticalSpacing: CGFloat = 0

    var boxBackgroundColor: UIColor = .primary

    var headerStyle: GNOTextStyle = .headline.color(.white)
    var titleStyle: GNOTextStyle = .body
    var valueStyle: GNOTextStyle = .title1

    enum TitleImage: String {
        case dark = "ico-shield-dark"
        case darkCircle = "ico-shield-circle-dark"
        case light = "ico-shield-light"
        case lightCircle = "ico-shield-circle-light"
    }
    var headerButtonImageName: String? = "ico-info-24"
    var headerButtonHidden: Bool = false

    var titleButtonImage: TitleImage? = .darkCircle
    var titleButtonImageName: String?

    var headerText: String?
    var titleText: String?
    var valueText: String?

    var headerTooltipText: NSAttributedString?
    var titleTooltipText: NSAttributedString?

    var tapAllocationHeaderButtonTrackingEvent: TrackingEvent?

    weak var tooltipHostView: UIView?

    private var headerTooltip: Tooltip?
    private var titleTooltip: Tooltip?

    // hide all tooltips before showing

    override func awakeFromNib() {
        super.awakeFromNib()
        style = .darkGuardian
    }

    @IBAction func didTapAllocationHeaderButton(_ sender: Any) {
        if let trackingEvent = tapAllocationHeaderButtonTrackingEvent {
            Tracker.trackEvent(trackingEvent)
        }
        showTooltip(text: headerTooltipText, existing: &headerTooltip, button: headerButton)
    }

    @IBAction func didTapAllocationTitleButton(_ sender: Any) {
        showTooltip(text: titleTooltipText, existing: &titleTooltip, button: titleButton)
    }

    private func showTooltip(text: NSAttributedString?, existing: inout Tooltip?, button: UIButton) {
        guard let host = tooltipHostView, let text = text else { return }

        if let tooltip = existing, tooltip.isVisible {
            tooltip.hide()
            return
        }

        NotificationCenter.default.post(name: .hideAllTooltips, object: self)

        existing = Tooltip.show(
            for: button,
            in: host,
            message: nil,
            attributedText: text,
            arrowTarget: button,
            aboveTarget: false,
            hideAutomatically: true,
            delegate: nil
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        headerText = nil
        titleText = nil
        valueText = nil
        headerTooltipText = nil
        titleTooltipText = nil
        update()
    }

    func update() {
        boxOuterTop.constant = boxOuterSpacing.top
        boxOuterBottom.constant = boxOuterSpacing.bottom
        boxOuterLeading.constant = boxOuterSpacing.left
        boxOuterTrailing.constant = boxOuterSpacing.right

        boxInnerTop.constant = boxInnerSpacing.top
        boxInnerBottom.constant = boxInnerSpacing.bottom
        boxInnerLeading.constant = boxInnerSpacing.left
        boxInnerTrailing.constant = boxInnerSpacing.right

        setNeedsUpdateConstraints()

        contentStack.spacing = contentVerticalSpacing
        headerStack.spacing = buttonHorizontalSpacing
        titleStack.spacing = buttonHorizontalSpacing
        bodyStack.spacing = bodyVerticalSpacing

        boxView.backgroundColor = boxBackgroundColor

        headerLabel.setStyle(headerStyle)
        headerLabel.text = headerText

        let headerImage = headerButtonImageName.flatMap { UIImage(named: $0) }
        headerButton.setImage(headerImage, for: .normal)
        headerButton.isHidden = headerButtonHidden

        titleLabel.setStyle(titleStyle)
        titleLabel.text = titleText

        let titleImage = (titleButtonImageName ?? titleButtonImage?.rawValue).flatMap { UIImage(named: $0) }
        titleButton.setImage(titleImage, for: .normal)

        valueLabel.setStyle(valueStyle)
        valueLabel.text = valueText
    }

    private func updateStyle() {
        switch style {
        case .darkGuardian:
            boxBackgroundColor = .primary
            headerStyle = .headlinePrimaryInverted
            titleStyle = .bodyPrimary.color(.primaryInverted)
            valueStyle = .title1.color(.primaryInverted)
            headerButtonHidden = true
            titleButtonImage = .darkCircle
            backgroundImage.isHidden = false

        case .lightGuardian:
            boxBackgroundColor = .backgroundPrimary
            headerStyle = .headline
            titleStyle = .bodyPrimary
            valueStyle = .title1
            headerButtonHidden = false
            titleButtonImage = .lightCircle
            backgroundImage.isHidden = true

        case .darkUser:
            boxBackgroundColor = .primary
            headerStyle = .headlinePrimaryInverted
            titleStyle = .bodyPrimary.color(.primaryInverted)
            valueStyle = .title1.color(.primaryInverted)
            headerButtonHidden = true
            titleButtonImage = .dark
            backgroundImage.isHidden = false

        case .lightUser:
            boxBackgroundColor = .backgroundPrimary
            headerStyle = .headline
            titleStyle = .bodyPrimary
            valueStyle = .title1
            headerButtonHidden = false
            titleButtonImage = .light
            backgroundImage.isHidden = true
        }

        update()
    }
}

class InfoButton: UIButton {
    var tapInsets: UIEdgeInsets = UIEdgeInsets(top: -20, left: -20, bottom: -20, right: -20)

    private var tapArea: CGRect {
        bounds.inset(by: tapInsets)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        tapArea.contains(point)
    }
}
