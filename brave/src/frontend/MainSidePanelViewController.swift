import Storage

class MainSidePanelViewController : UIViewController {

  let bookmarks: BookmarksPanel = BookmarksPanel()
  let history = HistoryPanel()

  var shadow: CALayer?
  let shadowLength = CGFloat(6)

  var bookmarksButton: UIButton = UIButton()
  var historyButton: UIButton = UIButton()

  override func viewDidLoad() {
    view.backgroundColor = UIColor.grayColor()
    bookmarks.profile = getApp().profile
    history.profile = getApp().profile

//
//    let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
//    let blurEffectView = UIVisualEffectView(effect: blurEffect)
//    blurEffectView.frame = view.bounds
//    blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
//    view.addSubview(blurEffectView)
    //    view.clipsToBounds = false;
    //    view.layer.shadowColor = UIColor.blackColor().CGColor
    //    view.layer.shadowOffset = CGSizeMake(5, 5);
    //    view.layer.shadowOpacity = 0.5;

    bookmarksButton.setTitle("Bookmarks", forState: UIControlState.Normal)
    view.addSubview(bookmarksButton)
     bookmarksButton.addTarget(self, action: "showBookmarks", forControlEvents: .TouchUpInside)

    historyButton.setTitle("History", forState: UIControlState.Normal)
    view.addSubview(historyButton)
    historyButton.addTarget(self, action: "showHistory", forControlEvents: .TouchUpInside)

    view.addSubview(history.view)
    view.addSubview(bookmarks.view)

    showBookmarks()

    shadow = drawInnerShadowOnView(view, length: shadowLength)
    shadow?.hidden = true

    bookmarks.view.hidden = false

    view.layer.masksToBounds = true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let f = view.frame
    shadow?.frame = CGRectMake(f.size.width - shadowLength, 0, shadowLength, f.size.height)
  }

  func setupConstraints() {
    bookmarksButton.snp_remakeConstraints {
      make in
      make.top.equalTo(view).offset(spaceForStatusBar())
      make.centerX.equalTo(view).dividedBy(2.0)
    }
    historyButton.snp_remakeConstraints {
      make in
      make.top.equalTo(view).offset(spaceForStatusBar())
      make.centerX.equalTo(view).multipliedBy(1.5)
    }

    bookmarks.view.snp_remakeConstraints { make in
      make.left.right.bottom.equalTo(view)
      make.top.equalTo(view).offset(verticalBottomPositionMainToolbar())
    }

    history.view.snp_remakeConstraints { make in
      make.left.right.bottom.equalTo(view)
      make.top.equalTo(view).offset(verticalBottomPositionMainToolbar())
    }
  }

  func showBookmarks() {
    history.view.hidden = true
    bookmarks.view.hidden = false
  }

  func showHistory() {
    bookmarks.view.hidden = true
    history.view.hidden = false
  }

  func spaceForStatusBar() -> Double {
    let spacer = BraveApp.isIPhonePortrait() ? 20.0 : 0.0
    return spacer
  }

  func verticalBottomPositionMainToolbar() -> Double {
    return Double(UIConstants.ToolbarHeight) + spaceForStatusBar()
  }

  func showAndSetDelegate(showing: Bool, delegate: HomePanelDelegate?) {
    shadow?.hidden = true
    if (showing) {
      bookmarks.homePanelDelegate = delegate
      bookmarks.reloadData()
      history.homePanelDelegate = delegate
      history.reloadData()
      setupConstraints()
    } else {
      bookmarks.homePanelDelegate = nil
      history.homePanelDelegate = nil
    }
  }

  func finishedShow() {
    shadow?.hidden = false
  }
//
//    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
//      coordinator.animateAlongsideTransition({ (cont) -> Void in
//        }, completion: nil)
//      super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
//    }
//
//    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
//      super.didRotateFromInterfaceOrientation(fromInterfaceOrientation)
//      var w:UIWebView = browser.webView
//  
//    }

}


