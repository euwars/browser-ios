/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Account
import Base32
import Shared
import UIKit
import XCGLogger

private var ShowDebugSettings: Bool = false
private var DebugSettingsClickCount: Int = 0

// The following are only here because we use master for L10N and otherwise these strings would disappear from the v1.0 release
private let Bug1204635_S1 = NSLocalizedString("Clear Everything", tableName: "ClearPrivateData", comment: "Title of the Clear private data dialog.")
private let Bug1204635_S2 = NSLocalizedString("Are you sure you want to clear all of your data? This will also close all open tabs.", tableName: "ClearPrivateData", comment: "Message shown in the dialog prompting users if they want to clear everything")
private let Bug1204635_S3 = NSLocalizedString("Clear", tableName: "ClearPrivateData", comment: "Used as a button label in the dialog to Clear private data dialog")
private let Bug1204635_S4 = NSLocalizedString("Cancel", tableName: "ClearPrivateData", comment: "Used as a button label in the dialog to cancel clear private data dialog")

// A base TableViewCell, to help minimize initialization and allow recycling.
class SettingsTableViewCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        indentationWidth = 0
        layoutMargins = UIEdgeInsetsZero
        // So that the seperator line goes all the way to the left edge.
        separatorInset = UIEdgeInsetsZero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// A base setting class that shows a title. You probably want to subclass this, not use it directly.
class Setting {
    private var _title: NSAttributedString?

    // The url the SettingsContentViewController will show, e.g. Licenses and Privacy Policy.
    var url: NSURL? { return nil }

    // The title shown on the pref.
    var title: NSAttributedString? { return _title }

    // An optional second line of text shown on the pref.
    var status: NSAttributedString? { return nil }

    // Whether or not to show this pref.
    var hidden: Bool { return false }

    var style: UITableViewCellStyle { return .Subtitle }

    var accessoryType: UITableViewCellAccessoryType { return .None }

    // Called when the cell is setup. Call if you need the default behaviour.
    func onConfigureCell(cell: UITableViewCell) {
        cell.detailTextLabel?.attributedText = status
        cell.textLabel?.attributedText = title
        cell.accessoryType = accessoryType
        cell.accessoryView = nil
    }

    // Called when the pref is tapped.
    func onClick(navigationController: UINavigationController?) { return }

    // Helper method to set up and push a SettingsContentViewController
    func setUpAndPushSettingsContentViewController(navigationController: UINavigationController?) {
        if let url = self.url {
            let viewController = SettingsContentViewController()
            viewController.settingsTitle = self.title
            viewController.url = url
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    init(title: NSAttributedString? = nil) {
        self._title = title
    }
}

// A setting in the sections panel. Contains a sublist of Settings
class SettingSection : Setting {
    private let children: [Setting]

    init(title: NSAttributedString? = nil, children: [Setting]) {
        self.children = children
        super.init(title: title)
    }

    var count: Int {
        var count = 0
        for setting in children {
            if !setting.hidden {
                count++
            }
        }
        return count
    }

    subscript(val: Int) -> Setting? {
        var i = 0
        for setting in children {
            if !setting.hidden {
                if i == val {
                    return setting
                }
                i++
            }
        }
        return nil
    }
}

// A helper class for settings with a UISwitch.
// Takes and optional settingsDidChange callback and status text.
class BoolSetting: Setting {
    private let prefKey: String
    private let prefs: Prefs
    private let defaultValue: Bool
    private let settingDidChange: ((Bool) -> Void)?
    private let statusText: String?

    init(prefs: Prefs, prefKey: String, defaultValue: Bool, titleText: String, statusText: String? = nil, settingDidChange: ((Bool) -> Void)? = nil) {
        self.prefs = prefs
        self.prefKey = prefKey
        self.defaultValue = defaultValue
        self.settingDidChange = settingDidChange
        self.statusText = statusText
        super.init(title: NSAttributedString(string: titleText, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override var status: NSAttributedString? {
        if let text = statusText {
            return NSAttributedString(string: text, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewHeaderTextColor])
        } else {
            return nil
        }
    }

    override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        let control = UISwitch()
        control.onTintColor = UIConstants.ControlTintColor
        control.addTarget(self, action: "switchValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        control.on = prefs.boolForKey(prefKey) ?? defaultValue
        cell.accessoryView = control
    }

    @objc func switchValueChanged(control: UISwitch) {
        prefs.setBool(control.on, forKey: prefKey)
        settingDidChange?(control.on)
    }
}

// A helper class for prefs that deal with sync. Handles reloading the tableView data if changes to
// the fxAccount happen.
private class AccountSetting: Setting, FxAContentViewControllerDelegate {
    unowned var settings: SettingsTableViewController

    var profile: Profile {
        return settings.profile
    }

    override var title: NSAttributedString? { return nil }

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    private override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        if settings.profile.getAccount() != nil {
            cell.selectionStyle = .None
        }
    }

    override var accessoryType: UITableViewCellAccessoryType { return .None }

    func contentViewControllerDidSignIn(viewController: FxAContentViewController, data: JSON) -> Void {
        if data["keyFetchToken"].asString == nil || data["unwrapBKey"].asString == nil {
            // The /settings endpoint sends a partial "login"; ignore it entirely.
            NSLog("Ignoring didSignIn with keyFetchToken or unwrapBKey missing.")
            return
        }

        // TODO: Error handling.
        let account = FirefoxAccount.fromConfigurationAndJSON(profile.accountConfiguration, data: data)!
        settings.profile.setAccount(account)

        // Reload the data to reflect the new Account immediately.
        settings.tableView.reloadData()
        // And start advancing the Account state in the background as well.
        settings.SELrefresh()

        settings.navigationController?.popToRootViewControllerAnimated(true)
    }

    func contentViewControllerDidCancel(viewController: FxAContentViewController) {
        NSLog("didCancel")
        settings.navigationController?.popToRootViewControllerAnimated(true)
    }
}

private class WithAccountSetting: AccountSetting {
    override var hidden: Bool { return !profile.hasAccount() }
}

private class WithoutAccountSetting: AccountSetting {
    override var hidden: Bool { return profile.hasAccount() }
}

// For great debugging!
private class HiddenSetting: Setting {
    let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var hidden: Bool {
        return !ShowDebugSettings
    }
}

extension NSFileManager {
    public func removeItemInDirectory(directory: String, named: String) throws {
        if let file = NSURL.fileURLWithPath(directory).URLByAppendingPathComponent(named).path {
            try self.removeItemAtPath(file)
        }
    }
}

private class DeleteExportedDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: delete exported databases", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        do {
            try NSFileManager.defaultManager().removeItemInDirectory(documentsPath, named: "browser.db")
        } catch {
            print("Couldn't delete exported data: \(error).")
        }
    }
}

private class ExportBrowserDataSetting: HiddenSetting {
    override var title: NSAttributedString? {
        // Not localized for now.
        return NSAttributedString(string: "Debug: copy databases to app container", attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override func onClick(navigationController: UINavigationController?) {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        if let browserDB = NSURL.fileURLWithPath(documentsPath).URLByAppendingPathComponent("browser.db").path {
            do {
                try self.settings.profile.files.copy("browser.db", toAbsolutePath: browserDB)
            } catch {
                print("Couldn't export browser data: \(error).")
            }
        }
    }
}

// Show the current version of Firefox
private class VersionSetting : Setting {
    let settings: SettingsTableViewController

    init(settings: SettingsTableViewController) {
        self.settings = settings
        super.init(title: nil)
    }

    override var title: NSAttributedString? {
        let appVersion = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let buildNumber = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as! String
        return NSAttributedString(string: String(format: NSLocalizedString("Version %@ (%@)", comment: "Version number of Firefox shown in settings"), appVersion, buildNumber), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }
    private override func onConfigureCell(cell: UITableViewCell) {
        super.onConfigureCell(cell)
        cell.selectionStyle = .None
    }

    override func onClick(navigationController: UINavigationController?) {
        if AppConstants.BuildChannel != .Aurora {
            DebugSettingsClickCount += 1
            if DebugSettingsClickCount >= 5 {
                DebugSettingsClickCount = 0
                ShowDebugSettings = !ShowDebugSettings
                settings.tableView.reloadData()
            }
        }
    }
}

// Opens the the license page in a new tab
private class LicenseAndAcknowledgementsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Licenses", comment: "Settings item that opens a tab containing the licenses. See http://mzl.la/1NSAWCG"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: NSURL? {
        return NSURL(string: WebServer.sharedInstance.URLForResource("license", module: "about"))
    }

    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens about:rights page in the content view controller
private class YourRightsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Your Rights", comment: "Your Rights settings section title"), attributes:
            [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: NSURL? {
        return NSURL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
    }

    private override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// Opens the search settings pane
private class SearchSetting: Setting {
    let profile: Profile

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    override var style: UITableViewCellStyle { return .Value1 }

    override var status: NSAttributedString { return NSAttributedString(string: profile.searchEngines.defaultEngine.shortName) }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        super.init(title: NSAttributedString(string: NSLocalizedString("Search", comment: "Open search section of settings"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = SearchSettingsTableViewController()
        viewController.model = profile.searchEngines
        navigationController?.pushViewController(viewController, animated: true)
    }
}

private class LoginsSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let loginsTitle = NSLocalizedString("Logins", comment: "Label used as an item in Settings. When touched, the user will be navigated to the Logins/Password manager.")
        super.init(title: NSAttributedString(string: loginsTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
    }
}

private class ClearPrivateDataSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryType: UITableViewCellAccessoryType { return .DisclosureIndicator }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let clearTitle = NSLocalizedString("Clear Private Data", comment: "Label used as an item in Settings. When touched it will open a dialog prompting the user to make sure they want to clear all of their private data.")
        super.init(title: NSAttributedString(string: clearTitle, attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor]))
    }

    override func onClick(navigationController: UINavigationController?) {
        let viewController = ClearPrivateDataTableViewController()
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

private class PrivacyPolicySetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: NSLocalizedString("Privacy Policy", comment: "Show Firefox Browser Privacy Policy page from the Privacy section in the settings. See https://www.mozilla.org/privacy/firefox/"), attributes: [NSForegroundColorAttributeName: UIConstants.TableViewRowTextColor])
    }

    override var url: NSURL? {
        return NSURL(string: "https://www.mozilla.org/privacy/firefox/")
    }

    override func onClick(navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController)
    }
}

// The base settings view controller.
class SettingsTableViewController: UITableViewController {
    private let Identifier = "CellIdentifier"
    private let SectionHeaderIdentifier = "SectionHeaderIdentifier"
    private var settings = [SettingSection]()

    var profile: Profile!
    var tabManager: TabManager!

    override func viewDidLoad() {
        super.viewDidLoad()

        let prefs = profile.prefs
        var generalSettings = [
            SearchSetting(settings: self),
            BoolSetting(prefs: prefs, prefKey: "blockPopups", defaultValue: true,
                titleText: NSLocalizedString("Block Pop-up Windows", comment: "Block pop-up windows setting")),
            BoolSetting(prefs: prefs, prefKey: "saveLogins", defaultValue: true,
                titleText: NSLocalizedString("Save Logins", comment: "Setting to enable the built-in password manager")),
        ]

      #if BRAVE
        generalSettings += [AdBlockSetting(settings:self),
                            VaultAddressSetting(settings: self)]
      #endif


        // There is nothing to show in the Customize section if we don't include the compact tab layout
        // setting on iPad. When more options are added that work on both device types, this logic can
        // be changed.
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            generalSettings +=  [
                BoolSetting(prefs: prefs, prefKey: "CompactTabLayout", defaultValue: true,
                    titleText: NSLocalizedString("Use Compact Tabs", comment: "Setting to enable compact tabs in the tab overview"))
            ]
        }

        settings += [
            //SettingSection(title: NSAttributedString(string: privacyTitle), children: privacySettings),
            //SettingSection(title: NSAttributedString(string: NSLocalizedString("Support", comment: "Support section title")), children: [
                //ShowIntroductionSetting(settings: self),
                //SendFeedbackSetting()
                //OpenSupportPageSetting()
            //]),
            SettingSection(title: NSAttributedString(string: NSLocalizedString("About", comment: "About settings section title")), children: [
                VersionSetting(settings: self),
                //LicenseAndAcknowledgementsSetting(),
                //YourRightsSetting(),
                //DisconnectSetting(settings: self),
                //ExportBrowserDataSetting(settings: self),
                //DeleteExportedDataSetting(settings: self),
            ])
        ]

        navigationItem.title = NSLocalizedString("Settings", comment: "Settings")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: "Done button on left side of the Settings view controller title bar"),
            style: UIBarButtonItemStyle.Done,
            target: navigationController, action: "SELdone")
        tableView.registerClass(SettingsTableViewCell.self, forCellReuseIdentifier: Identifier)
        tableView.registerClass(SettingsTableSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: SectionHeaderIdentifier)
        tableView.tableFooterView = SettingsTableFooterView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 128))

        tableView.separatorColor = UIConstants.TableViewSeparatorColor
        tableView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELsyncDidChangeState", name: ProfileDidStartSyncingNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "SELsyncDidChangeState", name: ProfileDidFinishSyncingNotification, object: nil)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        SELrefresh()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ProfileDidStartSyncingNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: ProfileDidFinishSyncingNotification, object: nil)
    }

    @objc private func SELsyncDidChangeState() {
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }

    @objc private func SELrefresh() {
        // Through-out, be aware that modifying the control while a refresh is in progress is /not/ supported and will likely crash the app.
        if let account = self.profile.getAccount() {
            account.advance().upon { _ in
                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                    self.tableView.reloadData()
                }
            }
        } else {
            self.tableView.reloadData()
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            var cell: UITableViewCell!
            if let _ = setting.status {
                // Work around http://stackoverflow.com/a/9999821 and http://stackoverflow.com/a/25901083 by using a new cell.
                // I could not make any setNeedsLayout solution work in the case where we disconnect and then connect a new account.
                // Be aware that dequeing and then ignoring a cell appears to cause issues; only deque a cell if you're going to return it.
                cell = SettingsTableViewCell(style: setting.style, reuseIdentifier: nil)
            } else {
                cell = tableView.dequeueReusableCellWithIdentifier(Identifier, forIndexPath: indexPath)
            }
            setting.onConfigureCell(cell)
            return cell
        }
        return tableView.dequeueReusableCellWithIdentifier(Identifier, forIndexPath: indexPath)
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return settings.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = settings[section]
        return section.count
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderIdentifier) as! SettingsTableSectionHeaderView
        let sectionSetting = settings[section]
        if let sectionTitle = sectionSetting.title?.string {
            headerView.titleLabel.text = sectionTitle
        }

        // Hide the top border for the top section to avoid having a double line at the top
        if section == 0 {
            headerView.showTopBorder = false
        } else {
            headerView.showTopBorder = true
        }

        return headerView
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // empty headers should be 13px high, but headers with text should be 44
        var height: CGFloat = 13
        let section = settings[section]
        if let sectionTitle = section.title {
            if sectionTitle.length > 0 {
                height = 44
            }
        }
        return height
    }

    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        let section = settings[indexPath.section]
        if let setting = section[indexPath.row] {
            setting.onClick(navigationController)
        }
        return nil
    }
}

class SettingsTableFooterView: UIView {
    var logo: UIImageView = {
        var image =  UIImageView(image: UIImage(named: "settingsFlatfox"))
        image.contentMode = UIViewContentMode.Center
        return image
    }()

    private lazy var topBorder: CALayer = {
        let topBorder = CALayer()
        topBorder.backgroundColor = UIConstants.SeparatorColor.CGColor
        return topBorder
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        layer.addSublayer(topBorder)
        addSubview(logo)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        topBorder.frame = CGRectMake(0.0, 0.0, frame.size.width, 0.5)
        logo.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
    }
}

class SettingsTableSectionHeaderView: UITableViewHeaderFooterView {
    var showTopBorder: Bool = true {
        didSet {
            topBorder.hidden = !showTopBorder
        }
    }

    var showBottomBorder: Bool = true {
        didSet {
            bottomBorder.hidden = !showBottomBorder
        }
    }

    var titleLabel: UILabel = {
        var headerLabel = UILabel()
        var frame = headerLabel.frame
        frame.origin.x = 15
        frame.origin.y = 25
        headerLabel.frame = frame
        headerLabel.textColor = UIConstants.TableViewHeaderTextColor
        headerLabel.font = UIFont.systemFontOfSize(12.0, weight: UIFontWeightRegular)
        return headerLabel
    }()

    private lazy var topBorder: CALayer = {
        let topBorder = CALayer()
        topBorder.backgroundColor = UIConstants.SeparatorColor.CGColor
        return topBorder
    }()

    private lazy var bottomBorder: CALayer = {
        let bottomBorder = CALayer()
        bottomBorder.backgroundColor = UIConstants.SeparatorColor.CGColor
        return bottomBorder
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIConstants.TableViewHeaderBackgroundColor
        addSubview(titleLabel)
        clipsToBounds = true
        layer.addSublayer(topBorder)
        layer.addSublayer(bottomBorder)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        bottomBorder.frame = CGRectMake(0.0, frame.size.height - 0.5, frame.size.width, 0.5)
        topBorder.frame = CGRectMake(0.0, 0.0, frame.size.width, 0.5)
        titleLabel.sizeToFit()
    }
}
