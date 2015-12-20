import Storage

class MainSidePanelViewController : UIViewController {

  let bookmarks: BookmarksPanel = BookmarksPanel()
  let history = HistoryPanel()

  let width = 300
  let headerHeight = 40

  var bookmarksButton: UIButton = UIButton()
  var historyButton: UIButton = UIButton()

  override func viewDidLoad() {
      view.backgroundColor = UIColor.blackColor()
//
//    let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
//    let blurEffectView = UIVisualEffectView(effect: blurEffect)
//    blurEffectView.frame = view.bounds
//    blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
//    view.addSubview(blurEffectView)

    bookmarksButton.setTitle("Bookmarks", forState: UIControlState.Normal)
    view.addSubview(bookmarksButton)

    bookmarksButton.snp_makeConstraints {
      make in
      make.top.equalTo(view).offset(spaceForStatusBar())
      make.centerX.equalTo(view).dividedBy(2.0)
    }
    bookmarksButton.addTarget(self, action: "showBookmarks", forControlEvents: .TouchUpInside)

    historyButton.setTitle("History", forState: UIControlState.Normal)
    view.addSubview(historyButton)
    historyButton.addTarget(self, action: "showHistory", forControlEvents: .TouchUpInside)

    historyButton.snp_makeConstraints {
      make in
      make.top.equalTo(view).offset(spaceForStatusBar())
      make.centerX.equalTo(view).multipliedBy(1.5)

//      make.left.equalTo(bookmarksButton!.snp_right).offset(12)
    }

    view.clipsToBounds = false;
    view.layer.shadowColor = UIColor.blackColor().CGColor
    view.layer.shadowOffset = CGSizeMake(0,5);
    view.layer.shadowOpacity = 0.5;

    bookmarks.profile = getApp().profile
    history.profile = getApp().profile

    showBookmarks()
  }

  func showBookmarks() {
    history.view.removeFromSuperview()

    view.addSubview(bookmarks.view)
    bookmarks.view.snp_makeConstraints { make in
      make.left.right.bottom.equalTo(view)
      make.top.equalTo(view).offset(headerHeight + spaceForStatusBar())
    }
  }

  func showHistory() {
    bookmarks.view.removeFromSuperview()

    view.addSubview(history.view)
    history.view.snp_makeConstraints { make in
      make.left.right.bottom.equalTo(view)
      make.top.equalTo(view).offset(headerHeight + spaceForStatusBar())
    }
  }

  func spaceForStatusBar() -> Int {
    let spacer = UIDevice.currentDevice().userInterfaceIdiom != .Phone ? 20 : 0
    return spacer
  }

  func showAndSetDelegate(showing: Bool, delegate: HomePanelDelegate?) {
    if (showing) {
      bookmarks.homePanelDelegate = delegate
      bookmarks.reloadData()
      history.homePanelDelegate = delegate
      history.reloadData()
    } else {
      bookmarks.homePanelDelegate = nil
      history.homePanelDelegate = nil
    }
  }
}


