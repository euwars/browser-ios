import Foundation


struct BraveUX {

  // set to true to show borders around views
  static let DebugShowBorders = false

  static let BackForwardDisabledButtonAlpha = CGFloat(0.1)

  static let LocationBarBackgroundColor_NonPrivateMode = UIColor(white: 77/255.0, alpha: 1)
  static let LocationBarTextColor = UIColor(white: 230/255.0, alpha: 1)

  // Interesting: compontents of the url can be colored differently: http://www.foo.com
  // Base: http://www and Host: foo.com
  static let LocationBarTextColor_URLBaseComponent = LocationBarTextColor
  static let LocationBarTextColor_URLHostComponent = LocationBarTextColor

  static let TextFieldCornerRadius = 14.0
  static let TextFieldBorderColor_HasFocus = UIColor.grayColor()
  static let TextFieldBorderColor_NoFocus = UIColor.blackColor()

  static let CancelTextColor = LocationBarTextColor
  // The toolbar button color (for the Normal state). Using default highlight color ATM
  static let ActionButtonTintColor = LocationBarTextColor

  static let AutocompleteTextFieldHighlightColor = UIColor.brownColor()

  static let BottomToolbarBackgroundColor = LocationBarBackgroundColor_NonPrivateMode

  // Yes it could be detected, just make life easier and set this number for now
  static let BottomToolbarNumberButtonsToRightOfBackForward = 3
  static let BackForwardButtonLeftOffset = CGFloat(7)

  // Internal use
  static let HeaderBackdropBackgroundColor = UIColor.blackColor()

}
