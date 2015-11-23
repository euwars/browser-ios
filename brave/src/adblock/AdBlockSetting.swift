import Foundation
import Shared

class AdBlockSetting: Setting {
  let prefs: Prefs
  let tabManager: TabManager!

  init(settings: SettingsTableViewController) {
    self.prefs = settings.profile.prefs
    self.tabManager = settings.tabManager
    let title = NSLocalizedString("Block Ads", comment: "Block ads on/off setting")
    let attributes = [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]
    super.init(title: NSAttributedString(string: title, attributes: attributes))
  }

  override func onConfigureCell(cell: UITableViewCell) {
    super.onConfigureCell(cell)
    let control = UISwitch()
    control.onTintColor = UIConstants.ControlTintColor
    control.addTarget(self, action: "switchValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
    control.on = prefs.boolForKey(AdBlocker.prefKeyAdBlockOn) ?? AdBlocker.prefKeyAdBlockOnDefaultValue
    cell.accessoryView = control
    cell.selectionStyle = .None
  }

  @objc func switchValueChanged(toggle: UISwitch) {
    prefs.setObject(toggle.on, forKey: AdBlocker.prefKeyAdBlockOn)
  }
}
