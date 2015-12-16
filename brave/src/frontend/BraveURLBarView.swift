
// To hide the curve effect
class HideCurveView : CurveView {
  override func drawRect(rect: CGRect) {}
}

class BraveURLBarView : URLBarView {

  private static weak var currentInstance: BraveURLBarView?

  override func commonInit() {
    BraveURLBarView.currentInstance = self
    locationContainer.layer.cornerRadius = CGFloat(BraveUX.TextFieldCornerRadius)
    curveShape = HideCurveView()
    super.commonInit()
  }

  override func updateAlphaForSubviews(alpha: CGFloat) {
    super.updateAlphaForSubviews(alpha)
    self.superview?.alpha = alpha
  }

  override func updateTabCount(count: Int, animated: Bool = true) {
    super.updateTabCount(count, animated: false)
    BraveBrowserToolbar.updateTabCountDuplicatedButton(count, animated: animated)
  }

  class func tabButtonPressed() {
    guard let instance = BraveURLBarView.currentInstance else { return }
    instance.delegate?.urlBarDidPressTabs(instance)
  }

  override var accessibilityElements: [AnyObject]? {
    get {
      if inOverlayMode {
        guard let locationTextField = locationTextField else { return nil }
        return [locationTextField, cancelButton]
      } else {
        if toolbarIsShowing {
          return [backButton, forwardButton, stopReloadButton, locationView, shareButton, bookmarkButton, tabsButton, progressBar]
        } else {
          return [stopReloadButton, locationView, bookmarkButton, progressBar]
        }
      }
    }
    set {
      super.accessibilityElements = newValue
    }
  }

  override func updateViewsForOverlayModeAndToolbarChanges() {
    super.updateViewsForOverlayModeAndToolbarChanges()
    if !self.toolbarIsShowing {
      self.stopReloadButton.hidden = false
      self.tabsButton.hidden = true
      self.bookmarkButton.hidden = false
    } else {
      self.tabsButton.hidden = false
    }

    if inOverlayMode {
      self.bookmarkButton.hidden = true
    }
  }

  override func updateConstraints() {
    super.updateConstraints()

    // I have to set this late (as in here) as it gets overridden if set earlier
    self.locationTextField?.backgroundColor = BraveUX.LocationTextEntryBackgroundColor
    // TODO : remove this entirely
    self.progressBar.alpha = 0.0

    if !inOverlayMode {
      self.locationContainer.snp_remakeConstraints { make in
        if self.toolbarIsShowing {
          // Firefox is not referring to the bottom toolbar, it is asking is this class showing more tool buttons
          make.leading.equalTo(self.stopReloadButton.snp_trailing)
          make.trailing.equalTo(self.shareButton.snp_leading)
        } else {
          make.leading.equalTo(self.stopReloadButton.snp_trailing)
          make.trailing.equalTo(self.bookmarkButton.snp_leading)  //.offset(-14)
        }

        make.height.equalTo(URLBarViewUX.LocationHeight)
        make.centerY.equalTo(self)
      }

      stopReloadButton.snp_remakeConstraints { make in
        if self.toolbarIsShowing {
          make.left.equalTo(self.forwardButton.snp_right)
          make.centerY.equalTo(self)
          make.size.equalTo(backButton)
        } else {
          make.left.centerY.equalTo(self)
          make.size.equalTo(UIConstants.ToolbarHeight)
        }
      }

      bookmarkButton.snp_remakeConstraints { make in
        if self.toolbarIsShowing {
          make.right.equalTo(self.tabsButton.snp_left)
          make.centerY.equalTo(self)
          make.size.equalTo(backButton)
        } else {
          make.right.equalTo(self)
          make.centerY.equalTo(self)
          make.size.equalTo(backButton)
        }
      }
    }
  }

  override func setupConstraints() {
    super.setupConstraints()
  }

  var progressIsCompleting = false
  override func updateProgressBar(progress: Float) {
    let minProgress = locationView.frame.width / 3.0

    func setWidth(width: CGFloat) {
      var frame = locationView.progressView.frame
      frame.size.width = width
      locationView.progressView.frame = frame
    }

    if progress == 1.0 {
      if progressIsCompleting {
        return
      }
      progressIsCompleting = true

      UIView.animateWithDuration(0.5, animations: {
        setWidth(self.locationView.frame.width)
        }, completion: { _ in
          UIView.animateWithDuration(0.5, animations: {
            self.locationView.progressView.alpha = 0.0
            }, completion: { _ in
              self.progressIsCompleting = false
              setWidth(0)
          })
      })
    } else {
      self.locationView.progressView.alpha = 1.0
      progressIsCompleting = false
      let w = minProgress + CGFloat(progress) * (self.locationView.frame.width - minProgress)

      if w > locationView.progressView.frame.size.width {
        UIView.animateWithDuration(0.5, animations: {
          self.locationView.progressView.frame = CGRectMake(0, 0, w, 40)
          }, completion: { _ in

        })
      }
    }
  }

}
