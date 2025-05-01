import Foundation
import UIKit
import GoogleMobileAds

enum AMBCoreError: Error {
    case notImplemented
    case unknown
}

protocol AMBHelperAdapter {}
extension AMBHelperAdapter {}

class AMBHelper {
    static let window = UIApplication.shared.windows.first { $0.isKeyWindow }!

    static var topAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return window.safeAreaLayoutGuide.topAnchor
        } else {
            return window.topAnchor
        }
    }
    static var bottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return window.safeAreaLayoutGuide.bottomAnchor
        } else {
            return window.bottomAnchor
        }
    }
    static var frame: CGRect {
        if #available(iOS 11.0, *) {
            return window.frame.inset(by: window.safeAreaInsets)
        } else {
            return window.frame
        }
    }

    let adapter: AMBHelperAdapter
    init(_ adapter: AMBHelperAdapter) { self.adapter = adapter }
}

protocol AMBCoreContext {
    func has(_ name: String) -> Bool
    func optBool(_ name: String) -> Bool?
    func optFloat(_ name: String) -> Float?
    func optInt(_ name: String) -> Int?
    func optString(_ name: String, _ defaultValue: String) -> String
    func optStringArray(_ name: String) -> [String]?

    func resolve(_ data: [String: Any])
    func resolve(_ data: Bool)
    func reject(_ msg: String)
}

extension AMBCoreContext {
    // convenience lookups
    func optString(_ name: String) -> String? {
        guard has(name) else { return nil }
        return optString(name, "")
    }
    func optAppMuted() -> Bool? { optBool("appMuted") }
    func optAppVolume() -> Float? { optFloat("appVolume") }
    func optId() -> String? { optString("id") }
    func optPosition() -> String { optString("position", "bottom") }
    func optAdUnitID() -> String? { optString("adUnitId") }
    func optAd() -> AMBCoreAd? {
        guard let id = optId(), let ad = AMBCoreAd.ads[id] else { return nil }
        return ad
    }
    func optAdOrError() -> AMBCoreAd? {
        if let ad = optAd() { return ad }
        reject("Ad not found: \(optId() ?? "-")")
        return nil
    }

    func optMaxAdContentRating() -> GADMaxAdContentRating? {
        switch optString("maxAdContentRating") {
        case "G":  return .general
        case "MA": return .matureAudience
        case "PG": return .parentalGuidance
        case "T":  return .teen
        default:   return nil
        }
    }
    func optChildDirectedTreatmentTag() -> Bool? { optBool("tagForChildDirectedTreatment") }
    func optUnderAgeOfConsentTag()   -> Bool? { optBool("tagForUnderAgeOfConsent") }
    func optTestDeviceIds()          -> [String]? { optStringArray("testDeviceIds") }

    /// — NEW: builds a `Request` instead of `GADRequest`
    func optRequest() -> Request {
        let request = Request()
        if let contentURL = optString("contentUrl") {
            request.contentURL = contentURL
        }
        if let kws = optStringArray("keywords") {
            request.keywords = kws
        }
        let extras = Extras()
        if let npa = optString("npa") {
            extras.additionalParameters = ["npa": npa]
        }
        request.register(extras)
        return request
    }

    func resolve() {
        resolve([:])
    }
    func resolve(_ data: Bool) {
        resolve(["value": data])
    }

    func reject() {
        reject(AMBCoreError.unknown.localizedDescription)
    }
    func reject(_ error: Error) {
        reject(error.localizedDescription)
    }

    /// — NEW: uses `MobileAds.shared` instead of `GADMobileAds.sharedInstance()`
    func configure() {
        // 1) muted API is now 'isApplicationMuted'
        if let muted = optAppMuted() {
            MobileAds.shared.isApplicationMuted = muted
        }
        // volume stays the same
        if let volume = optAppVolume() {
            MobileAds.shared.applicationVolume = volume
        }

        let rc = MobileAds.shared.requestConfiguration

        if let rating = optMaxAdContentRating() {
            rc.maxAdContentRating = rating
        }
        // 2) these two expect NSNumber? now, not Bool
        if let tag = optChildDirectedTreatmentTag() {
            rc.tagForChildDirectedTreatment = NSNumber(value: tag)
        }
        if let tag = optUnderAgeOfConsentTag() {
            rc.tagForUnderAgeOfConsent = NSNumber(value: tag)
        }
        if let devs = optTestDeviceIds() {
            rc.testDeviceIdentifiers = devs
        }

        if let sameAppKey = optBool("sameAppKey") {
            rc.setPublisherFirstPartyIDEnabled(sameAppKey)
        }
        if let pubID = optBool("publisherFirstPartyIDEnabled") {
            rc.setPublisherFirstPartyIDEnabled(pubID)
        }

        resolve()
    }

}

class AMBCoreAd: NSObject {
    static var ads = [String: AMBCoreAd]()

    let id: String
    let adUnitId: String
    let adRequest: Request   // ← now a `Request`

    init(id: String, adUnitId: String, adRequest: Request) {
        self.id = id
        self.adUnitId = adUnitId
        self.adRequest = adRequest
        super.init()
        AMBCoreAd.ads[id] = self
    }

    convenience init?(_ ctx: AMBCoreContext) {
        guard let id = ctx.optId(),
              let unit = ctx.optAdUnitID()
        else { return nil }
        self.init(id: id, adUnitId: unit, adRequest: ctx.optRequest())
    }

    deinit {
        let key = id
        DispatchQueue.main.async {
            AMBCoreAd.ads.removeValue(forKey: key)
        }
    }
}

// empty placeholder view
class AMBBannerPlaceholder: UIView {}
