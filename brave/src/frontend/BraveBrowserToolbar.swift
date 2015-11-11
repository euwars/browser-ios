// This is bottom toolbar

import SnapKit

class BraveBrowserToolbar : BrowserToolbar {

  lazy var tabsButton: TabsButton = {
    let tabsButton = TabsButton()
    tabsButton.titleLabel.text = "0"
    tabsButton.addTarget(self, action: "SELdidClickAddTab", forControlEvents: UIControlEvents.TouchUpInside)
    tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility Label for the tabs button in the browser toolbar")
    return tabsButton
  }()

  private weak var clonedTabsButton: TabsButton?

  private static weak var currentInstance: BraveBrowserToolbar?

  let backForwardUnderlay = UIImageView(image: UIImage(named: "backForwardUnderlay"))

  override init(frame: CGRect) {
    super.init(frame: frame)

    BraveBrowserToolbar.currentInstance = self

    backgroundColor = BraveUX.BottomToolbarBackgroundColor
    bookmarkButton.hidden = true
    stopReloadButton.hidden = true

    addSubview(tabsButton)
    addSubview(backForwardUnderlay)

    bringSubviewToFront(backButton)
    bringSubviewToFront(forwardButton)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  class func updateTabCountDuplicatedButton(count: Int, animated: Bool) {
    guard let instance = BraveBrowserToolbar.currentInstance else { return }
    URLBarView.updateTabCount(instance, tabsButton: instance.tabsButton,
      clonedTabsButton: &instance.clonedTabsButton, count: count, animated: animated)
  }

  func SELdidClickAddTab() {
    BraveURLBarView.tabButtonPressed()
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

    func common(make: ConstraintMaker) {
        make.centerY.equalTo(self)
        make.height.equalTo(UIConstants.ToolbarHeight)
    }

    backForwardUnderlay.snp_remakeConstraints { make in
      common(make)
      make.left.equalTo(backButton.snp_left)
      make.right.equalTo(forwardButton.snp_right)
    }

    backButton.snp_remakeConstraints { make in
      common(make)
      make.left.equalTo(self).offset(BraveUX.BackButtonLeftOffset)
      make.width.equalTo(BraveUX.BackButtonWidth)
    }

    forwardButton.snp_remakeConstraints { make in
      common(make)
      make.left.equalTo(self.backButton.snp_right)
      if BraveUX.ForwardButtonWidth > 0 {
        make.width.equalTo(BraveUX.ForwardButtonWidth)
      } else {
        make.width.equalTo(self).dividedBy(self.subviews.count - 1)
      }
    }

    shareButton.snp_remakeConstraints { make in
      common(make)
      make.left.equalTo(self.forwardButton.snp_right)
      make.width.equalTo(self).dividedBy(self.subviews.count - 1)
    }

    tabsButton.snp_remakeConstraints { make in
      common(make)
      make.left.equalTo(self.shareButton.snp_right)
      make.width.equalTo(self).dividedBy(self.subviews.count - 1)
    }

  }
}
