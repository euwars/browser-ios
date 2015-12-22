import Foundation


struct BraveUX {

  // I am considering using DeviceInfo.isBlurSupported() to set this, and reduce heavy animations
  static var IsHighLoadAnimationAllowed = true

  static let WidthOfSlideOut = 260

  // debug settings
  static var IsToolbarHidingOff = false
  static var IsOverrideScrollingSpeedAndMakeSlower = false // overrides IsHighLoadAnimationAllowed effect

  // set to true to show borders around views
  static let DebugShowBorders = false

  static let BackForwardDisabledButtonAlpha = CGFloat(0.3)
  static let BackForwardEnabledButtonAlpha = CGFloat(1.0)

  static let LocationBarBackgroundColor_NonPrivateMode = UIColor(white: 77/255.0, alpha: 0.3)
  static let LocationBarTextColor = UIColor(white: 230/255.0, alpha: 1)
  static let LocationTextEntryBackgroundColor = UIColor(white: 50/255.0, alpha: 1.0)

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

  // Yes it could be detected, just make life easier and set this number for now
  static let BottomToolbarNumberButtonsToRightOfBackForward = 3
  static let BackForwardButtonLeftOffset = CGFloat(10)

  static let ProgressBarColor = UIColor(colorLiteralRed: 0, green: 0, blue: 180/255.0, alpha: 1.0)

  // Internal use
  static let HeaderBackdropBackgroundColor = UIColor.blackColor()

}
