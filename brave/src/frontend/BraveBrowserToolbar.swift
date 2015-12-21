// This is bottom toolbar

import SnapKit

extension UIImage{

  func alpha(value:CGFloat)->UIImage
  {
    UIGraphicsBeginImageContextWithOptions(self.size, false, 0.0)

    let ctx = UIGraphicsGetCurrentContext();
    let area = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height);

    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    CGContextSetBlendMode(ctx, .Multiply);
    CGContextSetAlpha(ctx, value);
    CGContextDrawImage(ctx, area, self.CGImage);

    let newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
  }
}

class BraveBrowserToolbar : BrowserToolbar {
  static var tabsCount = 0

  lazy var tabsButton: TabsButton = {
    let tabsButton = TabsButton()
    tabsButton.titleLabel.text = "\(tabsCount)"
    tabsButton.addTarget(self, action: "onClickShowTabs", forControlEvents: UIControlEvents.TouchUpInside)
    tabsButton.accessibilityLabel = NSLocalizedString("Show Tabs",
      comment: "Accessibility Label for the tabs button in the browser toolbar")
    return tabsButton
  }()

  lazy var addTabButton: UIButton = {
    let button = UIButton()
    button.setImage(UIImage(named: "add"), forState: .Normal)
    //TODO button.setImage(UIImage(named: "backPressed"), forState: .Highlighted)
    //.accessibilityLabel = NSLocalizedString("Back", comment: "Accessibility Label for the browser toolbar Back button")
    button.addTarget(self, action: "onClickAddTab", forControlEvents: UIControlEvents.TouchUpInside)
    return button
  }()

  private weak var clonedTabsButton: TabsButton?
  var tabsContainer = UIView()

  private static weak var currentInstance: BraveBrowserToolbar?

  let backForwardUnderlay = UIImageView(image: UIImage(named: "backForwardUnderlay"))

  override init(frame: CGRect) {
    super.init(frame: frame)

    BraveBrowserToolbar.currentInstance = self

    bookmarkButton.hidden = true
    //stopReloadButton.hidden = true
    leftSlideOutButton.hidden = true

    tabsContainer.addSubview(tabsButton)
    addSubview(tabsContainer)
    addSubview(backForwardUnderlay)
    
    bringSubviewToFront(backButton)
    bringSubviewToFront(forwardButton)

    addSubview(addTabButton)

    if let img = forwardButton.imageView?.image {
      forwardButton.setImage(img.alpha(BraveUX.BackForwardDisabledButtonAlpha), forState: .Disabled)
    }
    if let img = backButton.imageView?.image {
      backButton.setImage(img.alpha(BraveUX.BackForwardDisabledButtonAlpha), forState: .Disabled)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  class func updateTabCountDuplicatedButton(count: Int, animated: Bool) {
    guard let instance = BraveBrowserToolbar.currentInstance else { return }
    tabsCount = count
    URLBarView.updateTabCount(instance.tabsButton,
      clonedTabsButton: &instance.clonedTabsButton, count: count, animated: animated)
  }

  func onClickAddTab() {
    let app = UIApplication.sharedApplication().delegate as! AppDelegate
    app.tabManager.addTabAndSelect()
    app.browserViewController.urlBar.browserLocationViewDidTapLocation(app.browserViewController.urlBar.locationView)
  }

  func onClickShowTabs() {
    BraveURLBarView.tabButtonPressed()
  }

  // I need to set this quite late or it is overridden
  // Calling this before doing the first layout is the easiest hack.
  // TODO: find less hacky-looking way
  func hackToSetButtonColor() {
    self.actionButtonTintColor = BraveUX.ActionButtonTintColor
    self.actionButtons.forEach { $0.tintColor = self.actionButtonTintColor }
  }

  override func updateConstraints() {
    backgroundColor = UIColor.clearColor()
    delay(0) {
      self.hackToSetButtonColor()
    }
    super.updateConstraints()

    var backButtonWidth = backButton.imageView?.image?.size.width ?? 0
    var forwardButtonWidth = backButton.imageView?.image?.size.width ?? 0

    func common(make: ConstraintMaker, bottomInset: Int = 0) {
      make.top.equalTo(self)
      make.bottom.equalTo(self).inset(bottomInset)
    }

    func commonButtonsToRightOfBackForward(make: ConstraintMaker, bottomInset: Int = 0) {
      common(make, bottomInset: bottomInset)
        //         make.width.equalTo(self.snp_width).dividedBy(Double(BraveUX.BottomToolbarNumberButtonsToRightOfBackForward) + 0.5)

      let bounds = UIScreen.mainScreen().bounds
      let w = min(bounds.width, bounds.height)

      make.width.equalTo((w - backButtonWidth - forwardButtonWidth - BraveUX.BackForwardButtonLeftOffset) /
        CGFloat(BraveUX.BottomToolbarNumberButtonsToRightOfBackForward))
    }

    backForwardUnderlay.snp_remakeConstraints { make in
      common(make)
      make.left.equalTo(backButton.snp_left)
      make.right.equalTo(forwardButton.snp_right)
    }

    backButton.snp_remakeConstraints { make in
      common(make)
      make.left.equalTo(self).offset(BraveUX.BackForwardButtonLeftOffset).priorityLow()
      make.width.equalTo(backButtonWidth)
    }

    forwardButton.snp_remakeConstraints { make in
      common(make)
      make.left.equalTo(self.backButton.snp_right)
      make.width.equalTo(forwardButtonWidth)
    }

    shareButton.snp_remakeConstraints { make in
      commonButtonsToRightOfBackForward(make)
      make.left.equalTo(self.forwardButton.snp_right)
    }

    tabsContainer.snp_remakeConstraints { make in
      commonButtonsToRightOfBackForward(make, bottomInset: 1)
      make.left.equalTo(self.addTabButton.snp_right)
    }

    addTabButton.snp_remakeConstraints { make in
      commonButtonsToRightOfBackForward(make)
      make.left.equalTo(self.shareButton.snp_right)
    }

    tabsButton.snp_remakeConstraints { make in
      make.center.equalTo(tabsContainer)
      make.top.equalTo(tabsContainer)
      make.bottom.equalTo(tabsContainer)
      make.width.equalTo(tabsButton.snp_height)
    }
  }
}
