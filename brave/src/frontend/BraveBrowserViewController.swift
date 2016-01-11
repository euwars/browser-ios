/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

class BraveBrowserViewController : BrowserViewController {
    override func applyTheme(themeName: String) {
        super.applyTheme(themeName)

        toolbar?.accessibilityLabel = "toolbar thing"
        headerBackdrop.accessibilityLabel = "headerBackdrop"
        webViewContainerBackdrop.accessibilityLabel = "webViewContainerBackdrop"
        webViewContainer.accessibilityLabel = "webViewContainer"
        statusBarOverlay.accessibilityLabel = "statusBarOverlay"
        urlBar.accessibilityLabel = "BraveUrlBar"
        headerBackdrop.backgroundColor = BraveUX.HeaderBackdropBackgroundColor

        header.blurStyle = .Dark
        footerBackground?.blurStyle = .Dark
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
            make.top.equalTo(self.statusBarOverlay.snp_bottom).offset(UIConstants.ToolbarHeight)
            make.height.equalTo(self.view.snp_height).offset(-BraveApp.statusBarHeight())
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

        let h = BraveApp.isIPhoneLandscape() ? 0 : 20
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
