

//
//  Copyright © 2018 Gnosis Ltd. All rights reserved.
//
import UIKit

/// Defines boilerplate initializers so that custom views would be usable when created both from code and Interface
/// Builder files.
///
/// Override `commonInit()` method in your subclass. You can also override `update()` method and call it on
/// `didSet` from your class's properties. Both methods do nothing by default.
///
/// # How to create UIScrollView in Interface Builder (IB) with a UIStackView as a content.
///
/// TIP: It helps to set a distinct background color in IB for each view you are working with to debug it.
/// Then you can override background colors in the code with actual values after you are fine with the result.
///
/// 1. Add UIScrollView (ScrollView) as a subview.
///    Constraint it to SafeArea (leading, trailing, top, bottom) with 0 constant.
/// 2. Add UIView (ContentView) inside the ScrollView.
///    Constraint it to UIScrollView's (leading, trailing, top, bottom) with 0 constant.
/// 3. Add 'Equal Widths' constraint from ContentView to ScrollView.
/// 4. Add UIView (WrapperView) inside ContentView.
///    Constraint it to ContentView's (leading, trailing, top) with constant 0,
///    and bottom with constant >= 0.
///    This bottom constraint keeps space after the content, so it the scroll view's
///    bottom content offset will be equal to that space.
/// 5. Add UIStackView (StackView) inside the WrapperView.
///    Constraint it to WrapperView (leading, trailing, top, bottom) with desired insets.
///
/// # How to create UIView (option: with dynamic height) via layout in IB. (SafeUIKit-based solution)
///
/// 1. Create your UIView (View) Swift class inheriting from BaseCustomView (import SafeUIKit).
/// 2. Create a xib file. Make the top view (WrapperView) size "Freeform" (Attributes Inspector)
/// 3. Set xib's File Owner to your custom View class.
/// 4. Connect WrapperView view to a property in the View class.
///    Do not put 'UIStackView' as a WrapperView, keep it UIView. Instead, add the stack view inside wrapper view.
/// 5. Override `commonInit()` method and call safeUIKit_loadFromNib(forClass: <View class>.self)
/// 6. Activate constraint from self.heightAnchor to WrapperView.heightAnchor.
/// 7. If your view has vertical stack view (StackView) inside WrapperView:
/// 8.     Constraint StackView's (leading, trailing, top) to the WrapperView.
/// 9.     In the code, add:
///
///     wrapperView.translatesAutoresizingMaskIntoConstraints = false
///     wrapperView.heightAnchor.constraint(equalTo: stackView.heightAnchor).isActive = true
///     wrapAroundDynamicHeightView(wrapperView)
///
/// ## How to use such View
/// Now you can use your View inside other XIB or Storyboard files - just add UIView and set its class to View.
///
/// If you are adding your View in the code, do it as usual - via `addSubview()` and then set the constraints.
/// If your View has dynamic (content-based) height, then after adding it as a subview, you can make its container
/// wrap around using the same `wrapAroundDynamicHeightView()` method as in the code above:
///
///     let myDynamicHeightView = View()
///     myDynamicHeightView.translatesAutoresizingMaskIntoConstraints = false
///     container.addSubview(myDynamicHeightView)
///     container.wrapAroundDynamicHeightView(myDynamicHeightView)
open class BaseCustomView: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    open override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }

    /// Common initializer called in `init(frame:)` and in `awakeFromNib()`
    /// The base implementation of this method does nothing.
    open func commonInit() {
        // meant for subclassing
    }

    /// Updates view after changing of the model values.
    /// The base implementation of this method does nothing.
    open func update() {
        // meant for subclassing
    }
}
