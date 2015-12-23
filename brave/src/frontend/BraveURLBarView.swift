
// To hide the curve effect
class HideCurveView : CurveView {
  override func drawRect(rect: CGRect) {}
}

class BraveURLBarView : URLBarView {

  private static weak var currentInstance: BraveURLBarView?
  lazy var leftSidePanelButton = { return UIButton() }()
  override func commonInit() {
    BraveURLBarView.currentInstance = self
    locationContainer.layer.cornerRadius = CGFloat(BraveUX.TextFieldCornerRadius)
    curveShape = HideCurveView()

    addSubview(leftSidePanelButton)
    super.commonInit()

    leftSidePanelButton.addTarget(self, action: "SELdidClickLeftSlideOut", forControlEvents: UIControlEvents.TouchUpInside)
    leftSidePanelButton.setImage(UIImage(named: "listpanel"), forState: .Normal)
  }

  override func updateAlphaForSubviews(alpha: CGFloat) {
    super.updateAlphaForSubviews(alpha)
    self.superview?.alpha = alpha
  }

  func SELdidClickLeftSlideOut() {
    NSNotificationCenter.defaultCenter().postNotificationName(kNotificationLeftSlideOutClicked, object: nil)
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
          return [backButton, forwardButton, leftSidePanelButton, locationView, stopReloadButton, shareButton, tabsButton]
        } else {
          return [leftSidePanelButton, locationView, stopReloadButton, progressBar]
        }
      }
    }
    set {
      super.accessibilityElements = newValue
    }
  }

  override func updateViewsForOverlayModeAndToolbarChanges() {
    super.updateViewsForOverlayModeAndToolbarChanges()
    self.leftSidePanelButton.hidden = inOverlayMode
    if !self.toolbarIsShowing {
      self.tabsButton.hidden = true
    } else {
      self.tabsButton.hidden = false
    }

    self.stopReloadButton.hidden = inOverlayMode

    progressBar.hidden = true
    bookmarkButton.hidden = true
  }

  override func prepareOverlayAnimation() {
    super.prepareOverlayAnimation()
    progressBar.hidden = true
    self.leftSidePanelButton.hidden = !self.toolbarIsShowing
    bookmarkButton.hidden = true
  }

  override func transitionToOverlay(didCancel: Bool = false) {
    self.leftSidePanelButton.alpha = inOverlayMode ? 0 : 1
    super.transitionToOverlay(didCancel)
    bookmarkButton.hidden = true
  }

  override func updateConstraints() {
    super.updateConstraints()

    curveShape.hidden = true
    bookmarkButton.hidden = true

    // I have to set this late (as in here) as it gets overridden if set earlier
    locationTextField?.backgroundColor = BraveUX.LocationTextEntryBackgroundColor
    stopReloadButton.tintColor = BraveUX.ActionButtonTintColor
    leftSidePanelButton.tintColor = BraveUX.ActionButtonTintColor
    // TODO : remove this entirely
    progressBar.hidden = true
    progressBar.alpha = 0.0

    bookmarkButton.snp_removeConstraints()
    curveShape.snp_removeConstraints()

    if !inOverlayMode {
      self.locationContainer.snp_remakeConstraints { make in
        if self.toolbarIsShowing {
          // Firefox is not referring to the bottom toolbar, it is asking is this class showing more tool buttons
          make.leading.equalTo(self.leftSidePanelButton.snp_trailing)
          make.trailing.equalTo(self.stopReloadButton.snp_leading)
        } else {
          make.leading.equalTo(self.leftSidePanelButton.snp_trailing)
          make.trailing.equalTo(self.stopReloadButton.snp_leading)  //.offset(-14)
        }

        make.height.equalTo(URLBarViewUX.LocationHeight)
        make.centerY.equalTo(self)
      }

      leftSidePanelButton.snp_remakeConstraints { make in
        if self.toolbarIsShowing {
          make.left.equalTo(self.forwardButton.snp_right)
          make.centerY.equalTo(self)
          make.size.equalTo(UIConstants.ToolbarHeight)
        } else {
          make.left.equalTo(self)
          make.centerY.equalTo(self)
          make.size.lessThanOrEqualTo(UIConstants.ToolbarHeight)
        }
      }

      stopReloadButton.snp_remakeConstraints { make in
        if self.toolbarIsShowing {
          make.right.equalTo(self.shareButton.snp_left)
          make.centerY.equalTo(self)
          make.size.equalTo(UIConstants.ToolbarHeight)
        } else {
          make.right.equalTo(self)
          make.centerY.equalTo(self)
          make.size.lessThanOrEqualTo(UIConstants.ToolbarHeight)
        }
      }
    }
  //  leftSidePanelButton.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10)
    stopReloadButton.contentEdgeInsets =  UIEdgeInsetsMake(0, 10, 0, 10)

  }

  override func setupConstraints() {
      super.setupConstraints()

      shareButton.snp_remakeConstraints { make in
        make.right.equalTo(self.tabsButton.snp_left)
        make.centerY.equalTo(self)
        make.width.equalTo(UIConstants.ToolbarHeight)
      }

      stopReloadButton.snp_remakeConstraints { make in
        make.right.equalTo(self.shareButton.snp_left)
        make.centerY.equalTo(self)
        make.size.equalTo(UIConstants.ToolbarHeight)
      }

      leftSidePanelButton.snp_makeConstraints { make in
        make.left.equalTo(self.forwardButton.snp_right)
        make.centerY.equalTo(self)
        make.size.equalTo(UIConstants.ToolbarHeight)
      }
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
          setWidth(w)
          }, completion: { _ in

        })
      }
    }
  }

}
