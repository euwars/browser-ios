import Shared

// To disable the blur effect
//class EmptyBlurWrapper :BlurWrapper {
//  override init(view: UIView) {
//    super.init(view: view)
//    effectView.removeFromSuperview()
//    effectView = UIVisualEffectView()
//  }
//
//  required init?(coder aDecoder: NSCoder) {
//    super.init(coder: aDecoder)
//  }
//}

class BraveBrowserViewController : BrowserViewController {
  override func applyNormalModeTheme(force force:Bool) {
    super.applyNormalModeTheme(force:false)
    header.blurStyle = .Dark
    footerBackground?.blurStyle = .Dark

    BrowserLocationView.appearance().baseURLFontColor = BraveUX.LocationBarTextColor_URLBaseComponent
    BrowserLocationView.appearance().hostFontColor =  BraveUX.LocationBarTextColor_URLHostComponent
    BrowserLocationView.appearance().backgroundColor = BraveUX.LocationBarBackgroundColor_NonPrivateMode

    ToolbarTextField.appearance().textColor = BraveUX.LocationBarTextColor
    ToolbarTextField.appearance().highlightColor = BraveUX.AutocompleteTextFieldHighlightColor
    ToolbarTextField.appearance().clearButtonTintColor = nil
    ToolbarTextField.appearance().backgroundColor = BraveUX.LocationBarBackgroundColor_NonPrivateMode

    URLBarView.appearance().locationBorderColor = BraveUX.TextFieldBorderColor_NoFocus
    URLBarView.appearance().locationActiveBorderColor = BraveUX.TextFieldBorderColor_HasFocus
    URLBarView.appearance().progressBarTint = URLBarViewUX.ProgressTintColor
    URLBarView.appearance().cancelTextColor = BraveUX.CancelTextColor
    URLBarView.appearance().actionButtonTintColor = BraveUX.ActionButtonTintColor
  }
}