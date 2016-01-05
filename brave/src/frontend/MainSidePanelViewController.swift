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
        triangleView.alpha = 0.9

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
        view.hidden = true
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

    private func show(showing: Bool) {
        if (showing) {
            view.hidden = false
            bookmarks.tableView.backgroundColor = UIColor(white: 242/255.0, alpha: 1.0)
            history.tableView.backgroundColor = bookmarks.tableView.backgroundColor
            setupConstraints()
        }
        view.layoutIfNeeded()

        let width = showing ? BraveUX.WidthOfSlideOut : 0
        let animation = {
            guard let superview = self.view.superview else { return }
            self.view.snp_remakeConstraints {
                make in
                make.bottom.left.top.equalTo(superview)
                make.width.equalTo(width)
            }
            superview.layoutIfNeeded()

            guard let topVC = getApp().rootViewController.visibleViewController else { return }
            topVC.setNeedsStatusBarAppearanceUpdate()
        }

        var percentComplete = Double(view.frame.width) / Double(BraveUX.WidthOfSlideOut)
        if showing {
            percentComplete = 1.0 - percentComplete
        }
        let duration = 0.2 * percentComplete
        UIView.animateWithDuration(duration, animations: animation)
        if (!showing) { // for reasons unknown, wheh put in a animation completion block, this is called immediately
            delay(duration) { self.view.hidden = true }
        }
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
        show(showing)
    }

    var loc = CGFloat(-1)
    func onTouchToHide(touchPoint: CGPoint, phase: UITouchPhase) {
        if view.hidden {
            return
        }

        let isFullWidth = fabs(view.frame.width - CGFloat(BraveUX.WidthOfSlideOut)) < 0.5
        
        func complete() {
            if isFullWidth {
                loc = CGFloat(-1)
                return
            }
            
            let shouldShow = view.frame.width / CGFloat(BraveUX.WidthOfSlideOut) > CGFloat(BraveUX.PanelClosingThresholdWhenDragging)
            if shouldShow {
                show(true)
            } else {
                showAndSetDelegate(false, delegate: nil)
            }
        }
        
        let isOnEdge = fabs(touchPoint.x - view.frame.width) < 10
        if !isOnEdge && loc < 0 && phase != .Began {
            return
        }
        
        switch phase {
        case .Began:  // A finger touched the screen
            loc = isOnEdge ? touchPoint.x : CGFloat(-1)
            break
        case .Moved, .Stationary:
            if loc < 0 || touchPoint.x > loc {
                complete()
                return
            }
            
            view.snp_remakeConstraints {
                make in
                make.bottom.left.top.equalTo(self.view.superview!)
                make.width.equalTo(CGFloat(BraveUX.WidthOfSlideOut) - (loc - touchPoint.x))
            }
            self.view.layoutIfNeeded()
            break
        case .Ended, .Cancelled:
            complete()
            break
        }
    }
}


