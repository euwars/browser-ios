/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class BraveMainWindow : UIWindow {

    let contextMenuHandler = BraveContextMenu()

    override func sendEvent(event: UIEvent) {
        super.sendEvent(event)
        contextMenuHandler.sendEvent(event, window: self)

        guard let braveTopVC = getApp().rootViewController.visibleViewController as? BraveTopViewController else { return }
        if let touches = event.touchesForWindow(self), let touch = touches.first where touches.count == 1 {
            braveTopVC.specialTouchEventHandling(touch.locationInView(self), phase: touch.phase)
        }
    }
}