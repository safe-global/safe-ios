//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//
import UIKit

public protocol FeedbackTooltipDelegate: AnyObject {

    func tooltipWillAppear(_ tooltip: FeedbackTooltip)
    func tooltipWillDisappear(_ tooltip: FeedbackTooltip)

}

public final class FeedbackTooltip: BaseCustomView {

    private let label = UILabel()
    private let background = UIImageView()

    private let button = UIButton(type: .custom)
    private let buttonSize: CGFloat = 27
    private let labelButtonSpace: CGFloat = 8

    private let arrowUp = Asset.greenTooltipArrow.image
    private let arrowDown = UIImage(cgImage: Asset.greenTooltipArrow.image.cgImage!,
                                    scale: Asset.greenTooltipArrow.image.scale,
                                    orientation: .downMirrored)
    private let arrow = UIImageView()
    private let arrowSize = CGSize(width: 16, height: 9)

    private var isShowingAboveTarget = true

    private let labelHorizontalInset: CGFloat = 12
    private let labelVerticalInset: CGFloat = 10

    private let horizontalEdgeInset: CGFloat = 15
    private let verticalPadding: CGFloat = 12

    private let userReadingSpeedCharsPerSecond: TimeInterval = 10
    private let appearanceDuration: TimeInterval = 0.3

    public private(set) var isVisible: Bool = false

    public weak var delegate: FeedbackTooltipDelegate?

    public override func commonInit() {
        background.image = Asset.whiteTooltipBackground.image
        addSubview(background)

        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = ColorName.darkBlue.color
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        addSubview(label)

        button.setImage(Asset.greenTooltipCross.image, for: .normal)
        button.addTarget(self, action: #selector(dismissTooltip), for: .touchUpInside)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissTooltip))
        addGestureRecognizer(tapRecognizer)
        isUserInteractionEnabled = true

        label.translatesAutoresizingMaskIntoConstraints = false
        background.translatesAutoresizingMaskIntoConstraints = false
        arrow.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: label.widthAnchor, constant: 2 * labelHorizontalInset),
            heightAnchor.constraint(equalTo: label.heightAnchor, constant: 2 * labelVerticalInset),

            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        addSubview(arrow)
        arrow.isHidden = true
    }

    // by default, the tooltip will be shown above the target view. Pass 'false' to show it below.
    public func setGreenStyle(aboveTarget: Bool = true) {
        isShowingAboveTarget = aboveTarget

        background.image = Asset.greenTooltipBackground.image

        label.textColor = ColorName.snowwhite.color
        label.font = UIFont.systemFont(ofSize: 16)

        arrow.image = isShowingAboveTarget ? arrowDown : arrowUp
        arrow.isHidden = false

        // reset constraints
        label.removeFromSuperview()
        addSubview(label)
        addSubview(button)

        button.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalTo: label.widthAnchor,
                                   constant: 2 * labelHorizontalInset + buttonSize + labelButtonSpace),
            heightAnchor.constraint(equalTo: label.heightAnchor, constant: 2 * labelVerticalInset),

            button.widthAnchor.constraint(equalToConstant: buttonSize),
            button.heightAnchor.constraint(equalToConstant: buttonSize),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -labelHorizontalInset),

            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: labelHorizontalInset),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -labelButtonSpace),
            label.heightAnchor.constraint(greaterThanOrEqualTo: button.heightAnchor),

            arrow.widthAnchor.constraint(equalToConstant: arrowSize.width),
            arrow.heightAnchor.constraint(equalToConstant: arrowSize.height)
        ])

    }

    @objc func dismissTooltip() {
        hide()
    }

    // swiftlint:disable multiline_arguments multiple_closures_with_trailing_closure
    private func show() {
        self.delegate?.tooltipWillAppear(self)
        isVisible = true
        UIView.animate(withDuration: appearanceDuration, delay: 0, options: [.allowUserInteraction], animations: {
            self.alpha = 1
        }, completion: nil)
    }

    public func hide(completion: (() -> Void)? = nil) {
        self.delegate?.tooltipWillDisappear(self)
        isVisible = false
        layer.removeAllAnimations()
        UIView.animate(withDuration: appearanceDuration, delay: 0, options: [], animations: {
            self.alpha = 0
        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
            completion?()
        })
    }

    @discardableResult
    public static func show(for view: UIView,
                            in superview: UIView,
                            message: String,
                            greenStyle: Bool = false,
                            aboveTarget: Bool = true,
                            hideAutomatically: Bool = true,
                            delegate: FeedbackTooltipDelegate? = nil) -> FeedbackTooltip {
        let tooltip = FeedbackTooltip()
        tooltip.delegate = delegate
        tooltip.label.text = message
        tooltip.alpha = 0
        superview.addSubview(tooltip)

        if greenStyle {
            tooltip.setGreenStyle(aboveTarget: aboveTarget)
        }

        // The idea is to show the tooltip within bounds, with the minimum possible width.
        //
        // ||-spacing-|   space for tooltip   |-spacing-||
        // ||         |<--max tooltip width ->|         ||
        // ||
        // ||           +-------+
        // ||           |tooltip| <-- centered relative to view below
        // ||           +---V---+
        // ||        |-----view----|
        // ||           +---^---+
        // ||           |tooltip| <-- centered relative to view above
        // ||           +-------+
        // tooltip.leading > superview.leading + padding
        // tooltip.trailing < superview.trailing - padding
        // tooltip.width < max width
        // tooltip.centerX = view.centerX
        // tooltip.bottom = view.top + verticalPadding // for above the target
        // tooltip.top = view.bottom + verticalPadding // for below the target
        // arrow.centerX = target.centerX
        // arrow.bottom = tooltip.top or arrow.top = tooltip.bottom
        // we use the superview to anchor the tooltip because if we used the target view to constraint tooltip position
        // then the target view posiition was changed by auto-layout.
        // swiftlint:disable line_length
        let maxTooltipWidth = superview.bounds.width - 2 * tooltip.horizontalEdgeInset
        let viewInSuperview = superview.convert(view.bounds, from: view)
        let constraints = [
            tooltip.centerXAnchor.constraint(equalTo: superview.leadingAnchor, constant: viewInSuperview.midX),
            tooltip.leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor, constant: tooltip.horizontalEdgeInset),
            tooltip.trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor, constant: -tooltip.horizontalEdgeInset),
            tooltip.widthAnchor.constraint(lessThanOrEqualToConstant: maxTooltipWidth),
            tooltip.arrow.centerXAnchor.constraint(equalTo: superview.leadingAnchor, constant: viewInSuperview.midX)
        ]

        // we reduce the priority of the tooltip centering constraint in order to be within the viewport bounds
        constraints[0].priority = .defaultHigh
        NSLayoutConstraint.activate(constraints)

        if tooltip.isShowingAboveTarget {
            tooltip.bottomAnchor.constraint(equalTo: superview.topAnchor,
                                            constant: viewInSuperview.minY - tooltip.verticalPadding).isActive = true
            tooltip.arrow.topAnchor.constraint(equalTo: tooltip.background.bottomAnchor).isActive = true
        } else {
            tooltip.topAnchor.constraint(equalTo: superview.topAnchor,
                                         constant: viewInSuperview.maxY + tooltip.verticalPadding).isActive = true
            tooltip.arrow.bottomAnchor.constraint(equalTo: tooltip.background.topAnchor).isActive = true
        }

        tooltip.show()

        guard hideAutomatically else { return tooltip }

        let visibleDurationSeconds = TimeInterval(message.count) / tooltip.userReadingSpeedCharsPerSecond
        // using asyncAfter instead of UIView.animation with delay because the latter blocks user interaction
        // even if the .allowUserInteraction passed as an option
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(visibleDurationSeconds * 1_000))) {
            tooltip.hide()
        }
        return tooltip
    }

}
// swiftlint:enable
