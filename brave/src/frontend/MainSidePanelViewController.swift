import Storage

class MainSidePanelViewController : UIViewController {

  var browser:BrowserViewController?

  let bookmarks = BookmarksPanel()
  let history = HistoryPanel()

  var bookmarksButton = UIButton()
  var historyButton = UIButton()

  let topButtonsView = UIView()
  let addBookmarkButton = UIButton()

  //let triangleViewContainer = UIView()
  let triangleView = UIImageView()

  let tabTitleViewContainer = UIView()
  let tabTitleView = UILabel()

  // Wrap everything in a UIScrollView the view animation will not try to shrink the view
  // add subviews to containerView not self.view
  let containerView = UIView()

  override func loadView() {
    self.view = UIScrollView(frame: UIScreen.mainScreen().bounds)
  }

  func viewAsScrollView() -> UIScrollView {
    return self.view as! UIScrollView
  }

  func setupContainerViewSize() {
    containerView.frame = CGRectMake(0, 0, CGFloat(BraveUX.WidthOfSlideOut), self.view.frame.height)
    viewAsScrollView().contentSize = CGSizeMake(containerView.frame.width, containerView.frame.height)
  }

  override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    setupContainerViewSize()
  }

  override func viewDidLoad() {
    viewAsScrollView().scrollEnabled = false

    view.addSubview(containerView)
    setupContainerViewSize()
    containerView.backgroundColor = UIColor(white: 77/255.0, alpha: 1.0)

    tabTitleViewContainer.backgroundColor = UIColor.whiteColor()
    tabTitleView.textColor = self.view.tintColor
    bookmarks.profile = getApp().profile
    history.profile = getApp().profile

    containerView.addSubview(topButtonsView)

    containerView.addSubview(tabTitleViewContainer)
    tabTitleViewContainer.addSubview(tabTitleView)
    topButtonsView.addSubview(triangleView)
    topButtonsView.addSubview(bookmarksButton)
    topButtonsView.addSubview(historyButton)
    topButtonsView.addSubview(addBookmarkButton)

    triangleView.image = UIImage(named: "triangle-nub")
    triangleView.contentMode = UIViewContentMode.Center

    bookmarksButton.setImage(UIImage(named: "bookmarklist"), forState: .Normal)
    bookmarksButton.addTarget(self, action: "showBookmarks", forControlEvents: .TouchUpInside)

    historyButton.setImage(UIImage(named: "history"), forState: .Normal)
    historyButton.addTarget(self, action: "showHistory", forControlEvents: .TouchUpInside)

    addBookmarkButton.addTarget(self, action: "addBookmark", forControlEvents: .TouchUpInside)
    addBookmarkButton.setImage(UIImage(named: "bookmark"), forState: .Normal)

    bookmarksButton.tintColor = BraveUX.ActionButtonTintColor
    historyButton.tintColor = BraveUX.ActionButtonTintColor
    addBookmarkButton.tintColor = UIColor.whiteColor()

    containerView.addSubview(history.view)
    containerView.addSubview(bookmarks.view)

    showBookmarks()

    bookmarks.view.hidden = false

    containerView.bringSubviewToFront(topButtonsView)
  }

  func addBookmark() {
    guard let tab = browser?.tabManager.selectedTab,
      let url = tab.displayURL?.absoluteString else {
        return
    }

    browser?.addBookmark(url, title: tab.title)
    showBookmarks()

    delay(0.1) {
      self.bookmarks.reloadData()
    }
  }

  func setupConstraints() {
//        containerView.snp_makeConstraints() {
//          make in
//          make.edges.equalTo(view)
//        }

    topButtonsView.snp_remakeConstraints {
      make in
      make.top.equalTo(containerView).offset(spaceForStatusBar())
      make.left.right.equalTo(containerView)
      make.height.equalTo(44.0)
    }

    historyButton.snp_remakeConstraints {
      make in
      make.bottom.equalTo(self.topButtonsView)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.centerX.equalTo(self.topButtonsView).dividedBy(2.0)
    }

    bookmarksButton.snp_remakeConstraints {
      make in
      make.bottom.equalTo(self.topButtonsView)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.centerX.equalTo(self.topButtonsView)
    }

    addBookmarkButton.snp_remakeConstraints {
      make in
      make.bottom.equalTo(self.topButtonsView)
      make.height.equalTo(UIConstants.ToolbarHeight)
      make.centerX.equalTo(self.topButtonsView).multipliedBy(1.5)
    }

    tabTitleViewContainer.snp_remakeConstraints {
      make in
      make.right.left.equalTo(containerView)
      make.top.equalTo(topButtonsView.snp_bottom)
      make.height.equalTo(44.0)
    }

    tabTitleView.snp_remakeConstraints {
      make in
      make.right.top.bottom.equalTo(tabTitleViewContainer)
      make.left.lessThanOrEqualTo(containerView).inset(24)
    }

    bookmarks.view.snp_remakeConstraints { make in
      make.left.right.bottom.equalTo(containerView)
      make.top.equalTo(tabTitleView.snp_bottom)
    }

    history.view.snp_remakeConstraints { make in
      make.left.right.bottom.equalTo(containerView)
      make.top.equalTo(tabTitleView.snp_bottom)
    }
  }

  func showBookmarks() {
    tabTitleView.text = "Bookmarks"
    history.view.hidden = true
    bookmarks.view.hidden = false
    moveTabIndicator(bookmarksButton)
  }

  func showHistory() {
    tabTitleView.text = "History"
    bookmarks.view.hidden = true
    history.view.hidden = false
    moveTabIndicator(historyButton)
  }

  func moveTabIndicator(button: UIButton) {
    triangleView.snp_remakeConstraints {
      make in
      make.width.equalTo(button)
      make.height.equalTo(6)
      make.left.equalTo(button)
      make.top.equalTo(button.snp_bottom)
    }
  }

  func spaceForStatusBar() -> Double {
    let spacer = BraveApp.isIPhoneLandscape() ? 0.0 : 20.0
    return spacer
  }

  func verticalBottomPositionMainToolbar() -> Double {
    return Double(UIConstants.ToolbarHeight) + spaceForStatusBar()
  }

  func showAndSetDelegate(showing: Bool, delegate: HomePanelDelegate?) {
    if (showing) {
      view.hidden = false
      bookmarks.tableView.backgroundColor = UIColor(white: 242/255.0, alpha: 1.0)
      history.tableView.backgroundColor = bookmarks.tableView.backgroundColor
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

  func finishedAnimation(showing showing: Bool) {
    if !showing { 
      view.hidden = true
    }
  }
}


