import GoogleMobileAds

class AMBContext: AMBCoreContext {
    func has(_ name: String) -> Bool {
        return opts?.value(forKey: name) != nil
    }

    func optBool(_ name: String) -> Bool? {
        return opt(name) as? Bool
    }

    func optFloat(_ name: String) -> Float? {
        return opt(name) as? Float
    }

    func optInt(_ name: String) -> Int? {
        return opt(name) as? Int
    }

    func optString(_ name: String, _ defaultValue: String) -> String {
        return (opt(name) as? String) ?? defaultValue
    }

    func optStringArray(_ name: String) -> [String]? {
        return opt(name) as? [String]
    }

    func resolve() {
        sendResult(CDVPluginResult(status: CDVCommandStatus_OK))
    }

    func resolve(_ msg: Bool) {
        sendResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg))
    }

    func resolve(_ msg: UInt) {
        sendResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: msg))
    }

    func resolve(_ data: [String: Any]) {
        sendResult(CDVPluginResult(status: CDVCommandStatus_OK, messageAs: data))
    }

    func reject(_ msg: String) {
        sendResult(CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: msg))
    }

    static weak var plugin: AMBPlugin!
    let command: CDVInvokedUrlCommand

    init(_ command: CDVInvokedUrlCommand) {
        self.command = command
    }

    var plugin: AMBPlugin {
        return AMBContext.plugin
    }

    var commandDelegate: CDVCommandDelegate {
        return plugin.commandDelegate
    }

    func opt0() -> Any? {
        return command.argument(at: 0)
    }

    lazy var opts: NSDictionary? = {
        return opt0() as? NSDictionary
    }()

    func opt(_ key: String) -> Any? {
        return opts?.value(forKey: key)
    }

    func optOffset() -> CGFloat? {
        return opt("offset") as? CGFloat
    }

    func optBackgroundColor() -> UIColor? {
        if let bg = opt("backgroundColor") as? NSDictionary,
           let r = bg["r"] as? CGFloat,
           let g = bg["g"] as? CGFloat,
           let b = bg["b"] as? CGFloat,
           let a = bg["a"] as? CGFloat {
            return UIColor(red: r/255, green: g/255, blue: b/255, alpha: a/255)
        }
        return nil
    }

    func optMarginTop() -> CGFloat? {
        return opt("marginTop") as? CGFloat
    }

    func optMarginBottom() -> CGFloat? {
        return opt("marginBottom") as? CGFloat
    }

    // swiftlint:disable cyclomatic_complexity
    func optAdSize() -> AdSize {
        if let type = opt("size") as? Int {
            switch type {
            case 0: return AdSizeBanner
            case 1: return AdSizeLargeBanner
            case 2: return AdSizeMediumRectangle
            case 3: return AdSizeFullBanner
            case 4: return AdSizeLeaderboard
            default: break
            }
        }
        if let dict = opt("size") as? NSDictionary {
            if let adaptive = dict["adaptive"] as? String {
                var width = AMBHelper.frame.size.width
                if let w = dict["width"] as? CGFloat {
                    width = w
                }
                if adaptive == "inline",
                   let maxH = dict["maxHeight"] as? CGFloat {
                    return inlineAdaptiveBanner(width: width, maxHeight: maxH)
                } else {
                    switch dict["orientation"] as? String {
                    case "portrait":
                        return portraitAnchoredAdaptiveBanner(width: width)
                    case "landscape":
                        return landscapeAnchoredAdaptiveBanner(width: width)
                    default:
                        return currentOrientationAnchoredAdaptiveBanner(width: width)
                    }
                }
            } else if let w = dict["width"] as? Int,
                      let h = dict["height"] as? Int {
                return adSizeFor(cgSize: CGSize(width: w, height: h))
            }
        }
        return AdSizeBanner
    }
    // swiftlint:enable cyclomatic_complexity

    func optGADServerSideVerificationOptions() -> ServerSideVerificationOptions? {
        guard let ssv = opt("serverSideVerification") as? NSDictionary else {
            return nil
        }
        let options = ServerSideVerificationOptions()
        if let custom = ssv.value(forKey: "customData") as? String {
            options.customRewardText = custom
        }
        if let userId = ssv.value(forKey: "userId") as? String {
            options.userIdentifier = userId
        }
        return options
    }

    func optWebviewGoto() -> String {
        return command.argument(at: 0) as! String
    }

    private func sendResult(_ result: CDVPluginResult?) {
        commandDelegate.send(result, callbackId: command.callbackId)
    }
}
