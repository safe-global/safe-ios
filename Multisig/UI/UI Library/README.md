# How to create Scroll View xib?
The "ScrollViewTemplateXib.xib" is a template with a scroll view set up with
all constraints that needed for it to work. You can duplicate this template
and use it as a starting point for the screens that need scrollable content.

# How to create a reusable view based on xib file?
1. Create a class inheriting from UINibView
2. Create a "View" xib and name it the same as the class
3. Set the File owner to that class. DO NOT SET THE ROOT VIEW TO THE CLASS!

As a result, the contents of the xib will be added as a subview to the view
class, and they will be pinned to the edges of the class. If you need
to set specific width or height on the class, either do it in another
xib or storyboard where this view is used, or do it in code:

    override func commonInit() {
        super.commonInit()
        // add your constraints here.
    }
