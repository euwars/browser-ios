/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

// TODO this is just for development, figure out what to do with this setting
class VaultAddressSetting: Setting {
  let prefs: Prefs
  let tabManager: TabManager!


  init(settings: SettingsTableViewController) {
    self.prefs = settings.profile.prefs
    self.tabManager = settings.tabManager
    let title = NSLocalizedString("Vault Address", comment: " ")
    let attributes = [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]
    super.init(title: NSAttributedString(string: title, attributes: attributes))
  }

  override func onConfigureCell(cell: UITableViewCell) {
    super.onConfigureCell(cell)
    let control = UITextField(frame: CGRectMake(0, 0, 150,40))
    control.addTarget(self, action: "valueChanged:", forControlEvents: UIControlEvents.EditingDidEnd)
    if let setting = prefs.stringForKey(VaultManager.prefKeyServerAddress) {
      control.text = setting
    } else {
      control.text = VaultManager.prefKeyServerAddressDefaultValue
    }
    cell.accessoryView = control
    cell.selectionStyle = .None
  }

  @objc func valueChanged(textField: UITextField) {
    prefs.setObject(textField.text, forKey: VaultManager.prefKeyServerAddress)
  }
}
