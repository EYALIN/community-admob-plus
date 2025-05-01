import Foundation
import GoogleMobileAds

class AMBAppOpenAd: AMBAdBase, FullScreenContentDelegate {
    private var mAd: AppOpenAd?

    convenience init?(_ ctx: AMBContext) {
        guard let id = ctx.optId(),
              let adUnitId = ctx.optAdUnitID()
        else {
            return nil
        }

        self.init(id: id,
                  adUnitId: adUnitId,
                  adRequest: ctx.optRequest())
    }

    deinit {
        clear()
    }

    override func isLoaded() -> Bool {
        return mAd != nil
    }

    override func load(_ ctx: AMBContext) {
        clear()

        // Use the new Swift signature: load(with:request:) { … }
        AppOpenAd.load(
            with: self.adUnitId,
            request: adRequest
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                self.emit(AMBEvents.adLoadFail, error)
                ctx.reject(error)
                return
            }

            guard let appOpenAd = ad else {
                let err = NSError(
                    domain: "AMBAppOpenAd",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to load App Open ad"]
                )
                self.emit(AMBEvents.adLoadFail, err)
                ctx.reject(err)
                return
            }

            appOpenAd.fullScreenContentDelegate = self
            self.mAd = appOpenAd
            self.emit(AMBEvents.adLoad)
            ctx.resolve()
        }
    }

    override func show(_ ctx: AMBContext) {
        guard let ad = mAd else {
            ctx.reject("App Open ad not ready")
            return
        }

        // Use the new Swift signature: present(from:)
        ad.present(from: plugin.viewController)
        ctx.resolve()
    }

    // MARK: - FullScreenContentDelegate

    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        emit(AMBEvents.adImpression)
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        clear()
        emit(AMBEvents.adShowFail, error)
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        emit(AMBEvents.adShow)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        clear()
        emit(AMBEvents.adDismiss)
    }

    // MARK: - Helpers

    private func clear() {
        mAd?.fullScreenContentDelegate = nil
        mAd = nil
    }
}
