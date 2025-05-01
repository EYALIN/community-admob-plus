import GoogleMobileAds

class AMBInterstitial: AMBAdBase, FullScreenContentDelegate {
    private var mAd: InterstitialAd?

    deinit {
        clear()
    }

    override func isLoaded() -> Bool {
        return mAd != nil
    }

    override func load(_ ctx: AMBContext) {
        clear()

        // New Swift signature: load(with:request:) { … }
        InterstitialAd.load(
            with: adUnitId,
            request: adRequest
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                self.emit(AMBEvents.adLoadFail, error)
                ctx.reject(error)
                return
            }

            guard let interstitial = ad else {
                let err = NSError(
                    domain: "AMBInterstitial",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to load interstitial ad"]
                )
                self.emit(AMBEvents.adLoadFail, err)
                ctx.reject(err)
                return
            }

            self.mAd = interstitial
            interstitial.fullScreenContentDelegate = self
            self.emit(AMBEvents.adLoad)
            ctx.resolve()
        }
    }

    override func show(_ ctx: AMBContext) {
        guard let ad = mAd else {
            ctx.reject("Interstitial ad not ready")
            return
        }

        // New Swift signature: present(from:) with no reward handler
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
