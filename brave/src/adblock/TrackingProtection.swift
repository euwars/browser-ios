private let _singleton = TrackingProtection()

class TrackingProtection {
    static let prefKeyTrackingProtectionOn = "braveTrackingProtection"
    static let dataVersion = "1"
    var isEnabled = true

    var parser: TrackingProtectionCpp = TrackingProtectionCpp()

    lazy var networkFileLoader: NetworkDataFileLoader = {
        let dataUrl = NSURL(string: "https://s3.amazonaws.com/tracking-protection-data/\(dataVersion)/TrackingProtection.dat")!
        let dataFile = "tp-data-\(dataVersion).dat"
        let loader = NetworkDataFileLoader(url: dataUrl, file: dataFile, localDirName: "tp-data")
        loader.delegate = self
        return loader
    }()

    class var singleton: TrackingProtection {
        return _singleton
    }

    private init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "prefsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
        updateEnabledState()
    }

    func updateEnabledState() {
        let obj = BraveApp.getPref(TrackingProtection.prefKeyTrackingProtectionOn)
        isEnabled = obj as? Bool ?? true
    }

    @objc func prefsChanged(info: NSNotification) {
        updateEnabledState()
    }

    func shouldBlock(request: NSURLRequest) -> Bool {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if !isEnabled {
            return false
        }

        guard let url = request.URL,
            var mainDocDomain = request.mainDocumentURL?.host else {
                return false
        }

        mainDocDomain = stripGenericSubdomainPrefixFromUrl(stripLocalhostWebServer(mainDocDomain))

        guard var host = url.host else { return false}
        if host.contains(mainDocDomain) {
            return false // ignore top level doc
        }

        host = stripGenericSubdomainPrefixFromUrl(stripLocalhostWebServer(host))

        let isBlocked = parser.checkHostIsBlocked(host, mainDocumentHost: mainDocDomain)

        //if isBlocked { print("blocked \(url.absoluteString)") }
        return isBlocked
    }
}

extension TrackingProtection: NetworkDataFileLoaderDelegate {
    func setDataFile(data: NSData?) {
        parser.setDataFile(data)
    }

    func hasDataFile() -> Bool {
        return parser.hasDataFile()
    }
}

