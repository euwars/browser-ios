import Storage

class MainSidePanelViewController : UIViewController {

  let bookmarks: BookmarksPanel = BookmarksPanel()
  let history = HistoryPanel()

  var bookmarksButton: UIButton = UIButton()
  var historyButton: UIButton = UIButton()

  override func viewDidLoad() {
    view.backgroundColor = UIColor.grayColor()
    bookmarks.profile = getApp().profile
    history.profile = getApp().profile

    bookmarksButton.setTitle("Bookmarks", forState: UIControlState.Normal)
    view.addSubview(bookmarksButton)
     bookmarksButton.addTarget(self, action: "showBookmarks", forControlEvents: .TouchUpInside)

    historyButton.setTitle("History", forState: UIControlState.Normal)
    view.addSubview(historyButton)
    historyButton.addTarget(self, action: "showHistory", forControlEvents: .TouchUpInside)

    view.addSubview(history.view)
    view.addSubview(bookmarks.view)

    showBookmarks()

    bookmarks.view.hidden = false

    view.layer.masksToBounds = true
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
  }
}


