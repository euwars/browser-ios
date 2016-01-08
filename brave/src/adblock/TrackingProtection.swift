private let _singleton = TrackingProtection()

class TrackingProtection {
    static let prefKeyBraveTPOn = "braveTrackingProtection"
    static let prefKeyBraveTPOnDefaultValue = true
    static let dataVersion = "0"
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


    func shouldBlock(request: NSURLRequest) -> Bool {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if !isEnabled {
            return false
        }

        guard let url = request.URL,
            domain = request.mainDocumentURL?.hostWithGenericSubdomainPrefixRemoved() else {
                return false
        }

        let isBlocked = parser.checkHostIsBlocked(url.hostWithGenericSubdomainPrefixRemoved(), mainDocumentHost: domain)

        if isBlocked {
            print("blocked \(url.absoluteString)")
        }
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

