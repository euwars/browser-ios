import Shared
import Storage

let kNotificationLeftSlideOutClicked = "kNotificationLeftSlideOutClicked"

class BraveTopViewController : UIViewController {
  var browser:BraveBrowserViewController
  var mainSidePanel:MainSidePanelViewController
  var leftSlideOutShowing = false

  var clickDetectionView = UIButton()

  init(browser:BraveBrowserViewController) {
    self.browser = browser
    mainSidePanel = MainSidePanelViewController()
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  private func addVC(vc: UIViewController) {
    addChildViewController(vc)
    view.addSubview(vc.view)
    vc.didMoveToParentViewController(self)
  }

  override func viewDidLoad() {
    view.accessibilityLabel = "HighestView"
    view.backgroundColor = UIColor.blackColor()

    browser.view.accessibilityLabel = "BrowserView"

    addVC(browser)
    addVC(mainSidePanel)

    mainSidePanel.view.snp_makeConstraints {
      make in
      make.bottom.left.top.equalTo(view)
      make.width.equalTo(0)
    }


//    clickDetectionView.layer.shadowColor = UIColor.redColor().CGColor
//    clickDetectionView.layer.shadowOffset = CGSizeMake(-4, 0)
//    clickDetectionView.layer.shadowOpacity = 0.7
//    clickDetectionView.layer.shadowRadius = 8.0

    clickDetectionView.backgroundColor = UIColor(white: 100/255, alpha: 0.05)

    setupBrowserConstraints(useTopLayoutGuide: true)

    NSNotificationCenter.defaultCenter().addObserver(self, selector: "leftSlideOutClicked:", name: kNotificationLeftSlideOutClicked, object: nil)

    clickDetectionView.addTarget(self, action: "dismissSlideOut", forControlEvents: UIControlEvents.TouchUpInside)

    mainSidePanel.browser = browser
  }

  func dismissSlideOut() {
    toggleLeftPanel()
  }

  private func setupBrowserConstraints(useTopLayoutGuide useTopLayoutGuide: Bool) {
    browser.view.snp_remakeConstraints {
      make in
      make.bottom.equalTo(view)
      if useTopLayoutGuide {
        make.top.equalTo(snp_topLayoutGuideTop)
      } else {
        make.top.equalTo(view).inset(20)
      }
      make.left.equalTo(mainSidePanel.view.snp_right)
      if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
        make.width.equalTo(view.snp_width)
      } else {
        make.right.equalTo(view)
      }
    }
  }

  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }

  override func prefersStatusBarHidden() -> Bool {
    if UIDevice.currentDevice().userInterfaceIdiom != .Phone {
      return super.prefersStatusBarHidden()
    }

    if BraveApp.isIPhoneLandscape() {
      return true
    }

    return leftSlideOutShowing
  }

  func leftSlideOutClicked(_:NSNotification) {
    toggleLeftPanel()
  }

  func toggleLeftPanel() {
    leftSlideOutShowing = !leftSlideOutShowing
    mainSidePanel.showAndSetDelegate(leftSlideOutShowing, delegate:self)
    mainSidePanel.view.layoutIfNeeded()

    if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
      if leftSlideOutShowing {
        view.addSubview(clickDetectionView)
        clickDetectionView.snp_remakeConstraints {
          make in
          make.edges.equalTo(browser.view)
        }
        clickDetectionView.layoutIfNeeded()
      } else {
        clickDetectionView.removeFromSuperview()
      }
    }
    
    let width = leftSlideOutShowing ? BraveUX.WidthOfSlideOut : 0
    let animation = {
      self.mainSidePanel.view.snp_remakeConstraints {
        make in
        make.bottom.left.top.equalTo(self.view)
        make.width.equalTo(width)
      }
      self.view.layoutIfNeeded()
      self.setNeedsStatusBarAppearanceUpdate()
    }

    UIView.animateWithDuration(0.2, animations: animation, completion: {
      finished in
      self.mainSidePanel.finishedAnimation(showing: width != 0)
    })
  }
}

extension BraveTopViewController : HomePanelDelegate {
  func homePanelDidRequestToSignIn(homePanel: HomePanel) {}
  func homePanelDidRequestToCreateAccount(homePanel: HomePanel) {}
  func homePanel(homePanel: HomePanel, didSelectURL url: NSURL, visitType: VisitType) {
    print("selected \(url)")
    browser.tabManager.selectedTab?.loadRequest(NSURLRequest(URL: url))
    toggleLeftPanel()
  }
}