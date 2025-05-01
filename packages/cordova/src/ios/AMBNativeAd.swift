import Foundation
import GoogleMobileAds
import UIKit

protocol AMBNativeAdViewProvider: NSObjectProtocol {
    func createView(_ nativeAd: NativeAd) -> UIView
    // delegate callbacks
    func didShow(_ ad: AMBNativeAd)
    func didHide(_ ad: AMBNativeAd)
}

extension AMBNativeAdViewProvider {
    func didShow(_ ad: AMBNativeAd) {}
    func didHide(_ ad: AMBNativeAd) {}
}

class AMBNativeAd: AMBAdBase, NativeAdLoaderDelegate, NativeAdDelegate {
    static var providers = [String: AMBNativeAdViewProvider]()

    private var mLoader: AdLoader!
    private let viewProvider: AMBNativeAdViewProvider
    private var mAd: NativeAd?
    private var ctxLoad: AMBContext?

    lazy var view: UIView = {
        return viewProvider.createView(mAd!)
    }()

    init(
        id: String,
        adUnitId: String,
        adRequest: Request,
        viewProvider: AMBNativeAdViewProvider
    ) {
        self.viewProvider = viewProvider
        super.init(id: id, adUnitId: adUnitId, adRequest: adRequest)

        mLoader = AdLoader(
          adUnitID: adUnitId,
          rootViewController: plugin.viewController,
          adTypes: [.native],
          options: nil
        )
        mLoader.delegate = self
    }

    convenience init?(_ ctx: AMBContext) {
        let viewName = ctx.optString("view") ?? "default"
        guard
            let id = ctx.optId(),
            let adUnitId = ctx.optAdUnitID(),
            let provider = Self.providers[viewName]
        else {
            return nil
        }
        self.init(
          id: id,
          adUnitId: adUnitId,
          adRequest: ctx.optRequest(),
          viewProvider: provider
        )
    }

    override func load(_ ctx: AMBContext) {
        ctxLoad = ctx
        mLoader.load(adRequest)
    }

    override func isLoaded() -> Bool {
        return mLoader != nil && !mLoader.isLoading
    }

    override func show(_ ctx: AMBContext) {
        if
          let x = ctx.opt("x") as? Double,
          let y = ctx.opt("y") as? Double,
          let w = ctx.opt("width") as? Double,
          let h = ctx.opt("height") as? Double
        {
            view.frame = CGRect(x: x, y: y, width: w, height: h)
        }

        if
          let root = plugin.viewController.view,
          view.superview != root
        {
            root.addSubview(view)
        }

        view.isHidden = false
        viewProvider.didShow(self)
    }

    override func hide(_ ctx: AMBContext) {
        view.isHidden = true
        viewProvider.didHide(self)
        ctx.resolve()
    }

    // MARK: - NativeAdLoaderDelegate

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        mAd = nativeAd
        nativeAd.delegate = self
        emit(AMBEvents.adLoad)

        if !adLoader.isLoading {
            ctxLoad?.resolve()
            ctxLoad = nil
        }
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        emit(AMBEvents.adLoadFail, error)

        if !adLoader.isLoading {
            ctxLoad?.reject(error.localizedDescription)
            ctxLoad = nil
        }
    }

    // MARK: - NativeAdDelegate

    func nativeAdDidRecordImpression(_ nativeAd: NativeAd) {
        emit(AMBEvents.adImpression, nativeAd)
    }

    func nativeAdDidRecordClick(_ nativeAd: NativeAd) {
        emit(AMBEvents.adClick, nativeAd)
    }

    func nativeAdWillPresentScreen(_ nativeAd: NativeAd) {
        emit(AMBEvents.adShow, nativeAd)
    }

    func nativeAdWillDismissScreen(_ nativeAd: NativeAd) {
        // no-op
    }

    func nativeAdDidDismissScreen(_ nativeAd: NativeAd) {
        emit(AMBEvents.adDismiss, nativeAd)
    }

    func nativeAdWillLeaveApplication(_ nativeAd: NativeAd) {
        // no-op
    }
}
