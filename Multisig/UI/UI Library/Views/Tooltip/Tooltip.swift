//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//
import UIKit

public protocol TooltipDelegate: AnyObject {
    func tooltipWillAppear(_ tooltip: Tooltip)
    func tooltipWillDisappear(_ tooltip: Tooltip)
}

extension NSNotification.Name {
    static let hideAllTooltips = NSNotification.Name("io.gnosis.safe.tooltip.hideAll")
}

public final class Tooltip: BaseCustomView {

    static let arrowUp = UIImage(named: "ico-tooltip-arrow")!
    static let arrowDown = UIImage(cgImage:  arrowUp.cgImage!,
                                    scale:  arrowUp.scale,
                                    orientation: .downMirrored)

    private let label = UILabel()
    private let background = UIImageView()

    private let arrow = UIImageView()
    private let arrowSize = CGSize(width: 16, height: 10)
    
    private var isShowingAboveTarget = true

    private let labelHorizontalInset: CGFloat = 12
    private let labelVerticalInset: CGFloat = 10

    private let labelStyle = GNOTextStyle.callout.color(.backgroundSecondary)

    private let horizontalEdgeInset: CGFloat = 15
    private let verticalPadding: CGFloat = 12

    private let userReadingSpeedCharsPerSecond: TimeInterval = 10
    private let appearanceDuration: TimeInterval = 0.3

    public private(set) var isVisible: Bool = false

    public weak var delegate: TooltipDelegate?

    public override func commonInit() {
        
        background.image = UIImage(named: "bkg-tooltip")
        addSubview(background)
        
        label.setStyle(labelStyle)
        label.numberOfLines = 0
        label.textAlignment = .left
        label.isUserInteractionEnabled = true
        addSubview(label)
        
        addSubview(arrow)

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
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: labelHorizontalInset),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: labelHorizontalInset),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: arrowSize.width),
            arrow.heightAnchor.constraint(equalToConstant: arrowSize.height),
            background.leadingAnchor.constraint(equalTo: leadingAnchor),
            background.trailingAnchor.constraint(equalTo: trailingAnchor),
            background.topAnchor.constraint(equalTo: topAnchor),
            background.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(dismissTooltip), name: .hideAllTooltips, object: nil)
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
                            message: String? = nil,
                            attributedText: NSAttributedString? = nil,
                            arrowTarget: UIView? = nil,
                            aboveTarget: Bool = true,
                            hideAutomatically: Bool = true,
                            delegate: TooltipDelegate? = nil) -> Tooltip {
        let tooltip = Tooltip()
        tooltip.delegate = delegate

        if let message = message {
            tooltip.label.text = message
        } else if let attributedText = attributedText {
            tooltip.label.attributedText = attributedText
        }

        tooltip.alpha = 0
        tooltip.isShowingAboveTarget = aboveTarget
        tooltip.arrow.image = aboveTarget ? Tooltip.arrowDown : Tooltip.arrowUp
        superview.addSubview(tooltip)

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
        var constraints = [
            tooltip.centerXAnchor.constraint(equalTo: superview.leadingAnchor, constant: viewInSuperview.midX),
            tooltip.leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor, constant: tooltip.horizontalEdgeInset),
            tooltip.trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor, constant: -tooltip.horizontalEdgeInset),
            tooltip.widthAnchor.constraint(lessThanOrEqualToConstant: maxTooltipWidth)
        ]
        
        if let arrowTarget = arrowTarget {
            
            let arrowInSuperview = superview.convert(arrowTarget.bounds, from: arrowTarget)
            
            constraints.append(
                tooltip.arrow.centerXAnchor.constraint(equalTo: superview.leadingAnchor, constant: arrowInSuperview.midX)
            )
            
        } else {
            constraints.append(
                tooltip.arrow.centerXAnchor.constraint(equalTo: superview.leadingAnchor, constant: viewInSuperview.midX)
            )
        }

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

        let messageLength = message?.count ?? attributedText?.length ?? 0

        let visibleDurationSeconds = TimeInterval(messageLength) / tooltip.userReadingSpeedCharsPerSecond
        // using asyncAfter instead of UIView.animation with delay because the latter blocks user interaction
        // even if the .allowUserInteraction passed as an option
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(visibleDurationSeconds * 1_000))) {
            tooltip.hide()
        }
        return tooltip
    }

}
// swiftlint:enable
