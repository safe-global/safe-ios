//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//
import UIKit

public class TooltipSource: TooltipDelegate {

    private weak var tooltip: Tooltip?
    private weak var target: UIView?
    private var arrowTarget: UIView?
    
    private var onTap: (() -> Void)?
    private var onAppear: (() -> Void)?
    private var onDisappear: (() -> Void)?

    public var isActive: Bool = true
    public var message: String?
    public var aboveTarget: Bool = true
    public var hideAutomatically: Bool = false

    public init(target: UIView,
                arrowTarget: UIView? = nil,
                onTap: (() -> Void)? = nil,
                onAppear: (() -> Void)? = nil,
                onDisappear: (() -> Void)? = nil) {
        self.target = target
        self.arrowTarget = arrowTarget
        self.onTap = onTap
        self.onAppear = onAppear
        self.onDisappear = onDisappear
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap))
        tapRecognizer.cancelsTouchesInView = false
        target.addGestureRecognizer(tapRecognizer)
        target.isUserInteractionEnabled = true
    }
    
    @objc private func hideTooltip() {
        if let tooltip = self.tooltip, tooltip.isVisible {
            tooltip.hide()
        }
    }

    @objc private func didTap() {
        if let tooltip = self.tooltip, tooltip.isVisible {
            tooltip.hide()
            return
        }
       
        guard isActive,
              let message = self.message, !message.isEmpty,
              let window = UIApplication.shared.keyWindow,
              let target = target else { return }
        // show only one at all times
        Self.hideAll()
        
        tooltip = Tooltip.show(
            for: target,
               in: window,
               message: message,
               arrowTarget: arrowTarget,
               aboveTarget: aboveTarget,
               hideAutomatically: hideAutomatically,
               delegate: self)
        
        onTap?()
    }

    public func tooltipWillAppear(_ tooltip: Tooltip) {
        onAppear?()
    }

    public func tooltipWillDisappear(_ tooltip: Tooltip) {
        onDisappear?()
    }

    static func hideAll() {
        guard let window = UIApplication.shared.keyWindow else { return }
        let allTooltips = window.subviews.compactMap { $0 as? Tooltip }
        for tooltip in allTooltips {
            tooltip.hide()
        }
    }
}
