
import Foundation
//http://stackoverflow.com/questions/30439581/uibutton-change-border-color-in-different-states-in-swift

// TODO get rid of this delay method
func delay(delay:Double, closure:()->()) {
  dispatch_after(
    dispatch_time(
      DISPATCH_TIME_NOW,
      Int64(delay * Double(NSEC_PER_SEC))
    ),
    dispatch_get_main_queue(), closure)
}

var defaultAlpha = CGFloat(0)

extension UIButton {
  override public var enabled: Bool {
    didSet {
      if (defaultAlpha == 0 ||
        (defaultAlpha != self.alpha && self.alpha != CGFloat(BraveUX.DisabledButtonAlpha))) {
        defaultAlpha = self.alpha
      }
      delay(0.3) {
        if self.enabled {
         // self.alpha = defaultAlpha
        } else {
          //self.alpha = CGFloat(BraveUX.DisabledButtonAlpha)
        }
      }
    }
  }
}