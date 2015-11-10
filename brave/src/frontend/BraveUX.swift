import Foundation


struct BraveUX {
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
  static let ActionButtonTintColor = LocationBarTextColor

  static let AutocompleteTextFieldHighlightColor = UIColor.brownColor()


  // Internal use
  static let HeaderBackdropBackgroundColor = UIColor.blackColor()
}
