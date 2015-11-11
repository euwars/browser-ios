import Shared

// To disable the blur effect
class EmptyBlurWrapper :BlurWrapper {
  override init(view: UIView) {

    if BraveUX.DebugShowBorders {
      UIView.bordersOn()
    }

    super.init(view: view)
    effectView.removeFromSuperview()
    effectView = UIVisualEffectView()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
}

class BraveBrowserViewController : BrowserViewController {
  override func applyNormalModeTheme() {
    super.applyNormalModeTheme()

    BrowserLocationView.appearance().baseURLFontColor = BraveUX.LocationBarTextColor_URLBaseComponent
    BrowserLocationView.appearance().hostFontColor =  BraveUX.LocationBarTextColor_URLHostComponent
    BrowserLocationView.appearance().backgroundColor = BraveUX.LocationBarBackgroundColor_NonPrivateMode

    ToolbarTextField.appearance().textColor = BraveUX.LocationBarTextColor
    ToolbarTextField.appearance().highlightColor = BraveUX.AutocompleteTextFieldHighlightColor
    ToolbarTextField.appearance().clearButtonTintColor = nil

    URLBarView.appearance().locationBorderColor = BraveUX.TextFieldBorderColor_NoFocus
    URLBarView.appearance().locationActiveBorderColor = BraveUX.TextFieldBorderColor_HasFocus
    URLBarView.appearance().progressBarTint = URLBarViewUX.ProgressTintColor
    URLBarView.appearance().cancelTextColor = BraveUX.CancelTextColor
    URLBarView.appearance().actionButtonTintColor = BraveUX.ActionButtonTintColor
  }
}