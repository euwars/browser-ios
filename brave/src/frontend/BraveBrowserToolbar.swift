// This is bottom toolbar

class BraveBrowserToolbar : BrowserToolbar {

  lazy var tabsButton: TabsButton = {
    let tabsButton = TabsButton()
    tabsButton.titleLabel.text = "0"
    tabsButton.addTarget(self, action: "SELdidClickAddTab", forControlEvents: UIControlEvents.TouchUpInside)
    tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility Label for the tabs button in the browser toolbar")
    return tabsButton
  }()

  override init(frame: CGRect) {
    super.init(frame: frame)

    self.backgroundColor = BraveUX.BottomToolbarBackgroundColor
    self.bookmarkButton.hidden = true
    self.stopReloadButton.hidden = true
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // I need to set this quite late or it is overridden
  // Calling this before doing the first layout is the easiest hack.
  // TODO: find less hacky-looking way
  func hackToSetButtonColor() {
    struct runOnce { static var hasRun = false }
    if (runOnce.hasRun) {
      return
    }
    runOnce.hasRun = true
    self.actionButtonTintColor = BraveUX.ActionButtonTintColor
    self.actionButtons.forEach { $0.tintColor = self.actionButtonTintColor }
  }

  override func updateConstraints() {
    hackToSetButtonColor()
    super.updateConstraints()

    backButton.snp_remakeConstraints { make in
      make.left.equalTo(self).offset(BraveUX.BackButtonLeftOffset)
      make.centerY.equalTo(self)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.width.equalTo(BraveUX.BackButtonWidth)
    }

    forwardButton.snp_remakeConstraints { make in
      make.left.equalTo(self.backButton.snp_right)
      make.centerY.equalTo(self)
      make.height.equalTo(UIConstants.ToolbarHeight)
      if BraveUX.ForwardButtonWidth > 0 {
        make.width.equalTo(BraveUX.ForwardButtonWidth)
      } else {
        make.width.equalTo(self).dividedBy(self.subviews.count)
      }
    }
  }
}
