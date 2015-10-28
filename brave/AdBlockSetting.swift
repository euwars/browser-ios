import Foundation
import Shared

class AdBlockSetting: Setting {
  let prefs: Prefs
  let tabManager: TabManager!

  static let prefKey = "braveBlockAds"
  static let defaultValue = true

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
    control.on = prefs.boolForKey(AdBlockSetting.prefKey) ?? AdBlockSetting.defaultValue
    cell.accessoryView = control
    cell.selectionStyle = .None
  }

  @objc func switchValueChanged(toggle: UISwitch) {
    prefs.setObject(toggle.on, forKey: AdBlockSetting.prefKey)
  }
}

// TODO this is just for development
class VaultAddressSetting: Setting {
  let prefs: Prefs
  let tabManager: TabManager!

  static let prefKey = "braveVaultServerAddress"
  static let defaultValue = "localhost:3000"

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
    control.placeholder = "localhost:3000"
    control.addTarget(self, action: "valueChanged:", forControlEvents: UIControlEvents.EditingDidEnd)
    if let setting = prefs.stringForKey(VaultAddressSetting.prefKey) {
      control.text = setting
    }
    cell.accessoryView = control
    cell.selectionStyle = .None
  }

  @objc func valueChanged(textField: UITextField) {
    prefs.setObject(textField.text, forKey: VaultAddressSetting.prefKey)
  }
 }
