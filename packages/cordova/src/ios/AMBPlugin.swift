#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
import GoogleMobileAds
import WebKit   // for WKWebView in webviewGoto

@objc(AMBPlugin)
class AMBPlugin: CDVPlugin {
    static func registerNativeAdViewProviders(_ providers: [String: AMBNativeAdViewProvider]) {
        AMBNativeAd.providers.merge(providers) { (_, new) in new }
    }

    private var readyCallbackId: String!

    deinit {
        readyCallbackId = nil
    }

    override func pluginInitialize() {
        super.pluginInitialize()
        AMBContext.plugin = self

        let stackView = AMBBannerStackView.shared
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        guard stackView.arrangedSubviews.isEmpty else { return }

        // Remove webView from old parent
        if let webView = self.webView {
            webView.removeFromSuperview()
            stackView.addArrangedSubview(webView)
        } else {
            print("❌ webView is nil")
            return
        }

        // (Optional) Add a banner placeholder view here
        // let placeholder = UIView()
        // stackView.insertArrangedSubview(placeholder, at: 0)

        let rootView = AMBContext.plugin.viewController.view!
        rootView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: rootView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor)
        ])


        if
          let x = commandDelegate.settings["disableSDKCrashReporting"] as? String,
          x.lowercased() == "true"
        {
            MobileAds.shared.disableSDKCrashReporting()
        }
    }

    @objc func ready(_ command: CDVInvokedUrlCommand) {
        readyCallbackId = command.callbackId
        DispatchQueue.global(qos: .background).async {
            self.emit(AMBEvents.ready, data: ["isRunningInTestLab": false])
        }
    }

    @objc func configure(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        ctx.configure()
    }

    @objc func configRequest(_ command: CDVInvokedUrlCommand) {
        // alias for configure
        let ctx = AMBContext(command)
        ctx.configure()
    }

    @objc func requestTrackingAuthorization(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                ctx.resolve(status.rawValue)
            }
        } else {
            ctx.resolve(false)
        }
    }

    @objc func start(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        MobileAds.shared.start { _ in
            // GADGetStringFromVersionNumber → free function `string(for:)`
            let versionString = string(
                for: MobileAds.shared.versionNumber
            )
            ctx.resolve(["version": versionString])
        }
    }

    @objc func setAppMuted(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        if let muted = ctx.opt0() as? Bool {
            MobileAds.shared.isApplicationMuted = muted
            ctx.resolve()
        } else {
            ctx.reject()
        }
    }

    @objc func setAppVolume(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        if let volume = ctx.opt0() as? Float {
            MobileAds.shared.applicationVolume = volume
            ctx.resolve()
        } else {
            ctx.reject()
        }
    }

    @objc func adCreate(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        DispatchQueue.main.async {
            guard let cls = ctx.optString("cls") else {
                ctx.reject()
                return
            }
            var ad: AMBCoreAd?
            switch cls {
            case "AppOpenAd":              ad = AMBAppOpenAd(ctx)
            case "BannerAd":               ad = AMBBanner(ctx)
            case "InterstitialAd":         ad = AMBInterstitial(ctx)
            case "NativeAd":               ad = AMBNativeAd(ctx)
            case "RewardedAd":             ad = AMBRewarded(ctx)
            case "RewardedInterstitialAd": ad = AMBRewardedInterstitial(ctx)
            default:                       break
            }
            if ad != nil {
                ctx.resolve()
            } else {
                ctx.reject("fail to create ad: \(ctx.optId() ?? "-")")
            }
        }
    }

    @objc func adIsLoaded(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        DispatchQueue.main.async {
            if let ad = ctx.optAdOrError() as? AMBAdBase {
                ctx.resolve(ad.isLoaded())
            }
        }
    }

    @objc func adLoad(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        DispatchQueue.main.async {
            if let ad = ctx.optAdOrError() as? AMBAdBase {
                ad.load(ctx)
            }
        }
    }

    @objc func adShow(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        DispatchQueue.main.async {
            if let ad = ctx.optAdOrError() as? AMBAdBase {
                if ad.isLoaded() {
                    ad.show(ctx)
                    ctx.resolve(true)
                } else {
                    ctx.resolve(false)
                }
            }
        }
    }

    @objc func adHide(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        DispatchQueue.main.async {
            if let ad = ctx.optAdOrError() as? AMBAdBase {
                ad.hide(ctx)
            }
        }
    }

    @objc func bannerConfig(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        DispatchQueue.main.async {
            AMBBanner.config(ctx)
        }
    }

    @objc func webviewGoto(_ command: CDVInvokedUrlCommand) {
        let ctx = AMBContext(command)
        DispatchQueue.main.async {
            if
              let url = URL(string: ctx.optWebviewGoto() + "#from_webview_goto"),
              let webView = self.webViewEngine.engineWebView as? WKWebView
            {
                webView.load(URLRequest(url: url))
            }
        }
    }

    // changed from `private` to internal so AMBAdBase can call `plugin.emit(...)`
    func emit(_ eventName: String, data: Any = NSNull()) {
        let result = CDVPluginResult(
            status: .ok,
            messageAs: ["type": eventName, "data": data]
        )
        result?.setKeepCallbackAs(true)
        commandDelegate.send(result, callbackId: readyCallbackId)
    }
}
