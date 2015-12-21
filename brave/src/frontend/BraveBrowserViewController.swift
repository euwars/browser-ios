import Shared

class BraveBrowserViewController : BrowserViewController {
  override func applyNormalModeTheme(force force:Bool) {
    super.applyNormalModeTheme(force:false)

    toolbar?.accessibilityLabel = "toolbar thing"
    headerBackdrop.accessibilityLabel = "headerBackdrop"
    webViewContainerBackdrop.accessibilityLabel = "webViewContainerBackdrop"
    webViewContainer.accessibilityLabel = "webViewContainer"
    statusBarOverlay.accessibilityLabel = "statusBarOverlay"
    urlBar.accessibilityLabel = "BraveUrlBar"
    headerBackdrop.backgroundColor = BraveUX.HeaderBackdropBackgroundColor

    header.blurStyle = .Dark
    footerBackground?.blurStyle = .Dark

    BrowserLocationView.appearance().baseURLFontColor = BraveUX.LocationBarTextColor_URLBaseComponent
    BrowserLocationView.appearance().hostFontColor =  BraveUX.LocationBarTextColor_URLHostComponent
    BrowserLocationView.appearance().backgroundColor = BraveUX.LocationBarBackgroundColor_NonPrivateMode

    ToolbarTextField.appearance().textColor = BraveUX.LocationBarTextColor
    ToolbarTextField.appearance().highlightColor = BraveUX.AutocompleteTextFieldHighlightColor
    ToolbarTextField.appearance().clearButtonTintColor = nil
    ToolbarTextField.appearance().backgroundColor = BraveUX.LocationBarBackgroundColor_NonPrivateMode

    URLBarView.appearance().locationBorderColor = BraveUX.TextFieldBorderColor_NoFocus
    URLBarView.appearance().locationActiveBorderColor = BraveUX.TextFieldBorderColor_HasFocus
    URLBarView.appearance().progressBarTint = URLBarViewUX.ProgressTintColor
    URLBarView.appearance().cancelTextColor = BraveUX.CancelTextColor
    URLBarView.appearance().actionButtonTintColor = BraveUX.ActionButtonTintColor
  }


  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)

    self.updateToolbarStateForTraitCollection(self.traitCollection)
    setupConstraints()
    if BraveApp.shouldRestoreTabs() {
        tabManager.restoreTabs()
    } else {
        tabManager.addTabAndSelect();
    }
    
    updateTabCountUsingTabManager(tabManager, animated: false)

    footer.accessibilityLabel = "footer"
    footerBackdrop.accessibilityLabel = "footerBackdrop"
  }

  func braveWebContainerConstraintSetup() {
      webViewContainer.snp_remakeConstraints { make in
        make.left.right.equalTo(self.view)

        if let readerModeBarBottom = readerModeBar?.snp_bottom {
          make.top.equalTo(readerModeBarBottom)
        } else {
          make.top.equalTo(self.header.snp_bottom)
        }

        if let toolbar = self.toolbar {
          make.bottom.equalTo(toolbar.snp_top)
        } else {
          make.bottom.equalTo(self.view)
        }
      }
  }

  override func setupConstraints() {
    super.setupConstraints()
    braveWebContainerConstraintSetup()
  }

  override func updateViewConstraints() {
    super.updateViewConstraints()

    // Setup the bottom toolbar
    toolbar?.snp_remakeConstraints { make in
      make.edges.equalTo(self.footerBackground!)
    }

    braveWebContainerConstraintSetup()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    let h = BraveApp.isIPhonePortrait() ? 20 : 0
    statusBarOverlay.snp_remakeConstraints { make in
      make.top.left.right.equalTo(self.view)
      make.height.equalTo(h)
    }
  }

  override func updateToolbarStateForTraitCollection(newCollection: UITraitCollection) {
    super.updateToolbarStateForTraitCollection(newCollection)
    braveWebContainerConstraintSetup()
  }
}