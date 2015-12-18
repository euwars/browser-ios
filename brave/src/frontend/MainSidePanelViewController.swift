import Foundation

class MainSidePanelViewController : UIViewController {

  var bookmarks: BookmarksPanel = BookmarksPanel()

  let width = 300
  let headerHeight = 40

  var bookmarksButton: UIButton?
  var historyButton: UIButton?

  override func viewDidLoad() {
      view.backgroundColor = UIColor.blackColor()
//
//    let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
//    let blurEffectView = UIVisualEffectView(effect: blurEffect)
//    blurEffectView.frame = view.bounds
//    blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
//    view.addSubview(blurEffectView)

    bookmarksButton = UIButton()
    bookmarksButton?.setTitle("Bookmarks", forState: UIControlState.Normal)
    view.addSubview(bookmarksButton!)

    bookmarksButton?.snp_makeConstraints {
      make in
      make.top.equalTo(view).offset(spaceForStatusBar())
      make.centerX.equalTo(view).dividedBy(2.0)
    }

    historyButton = UIButton()
    historyButton?.setTitle("History", forState: UIControlState.Normal)
    view.addSubview(historyButton!)

    historyButton?.snp_makeConstraints {
      make in
      make.top.equalTo(view).offset(spaceForStatusBar())
      make.centerX.equalTo(view).multipliedBy(1.5)

//      make.left.equalTo(bookmarksButton!.snp_right).offset(12)
    }
  }

  func spaceForStatusBar() -> Int {
    let spacer = UIDevice.currentDevice().userInterfaceIdiom != .Phone ? 20 : 0
    return spacer
  }

  override func viewDidAppear(animated: Bool) {
    guard let app = UIApplication.sharedApplication().delegate as? AppDelegate else { return }
    bookmarks.profile = app.profile
    view.addSubview(bookmarks.view)
    bookmarks.view.snp_makeConstraints { make in
      make.left.right.bottom.equalTo(view)
      make.top.equalTo(view).offset(headerHeight + spaceForStatusBar())
    }
  }

  override func viewDidDisappear(animated: Bool) {
    bookmarks.view.removeFromSuperview()
  }
}
