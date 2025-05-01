import GoogleMobileAds

class AMBRewardedInterstitial: AMBAdBase, FullScreenContentDelegate {
    private var mAd: RewardedInterstitialAd?

    deinit {
        clear()
    }

    override func isLoaded() -> Bool {
        return mAd != nil
    }

    override func load(_ ctx: AMBContext) {
        clear()

        // Use the new Swift overlay signature: load(with:request:) { … }
        RewardedInterstitialAd.load(
            with: adUnitId,
            request: adRequest
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                self.emit(AMBEvents.adLoadFail, error)
                ctx.reject(error)
                return
            }

            guard let interstitialAd = ad else {
                let err = NSError(
                    domain: "AMBRewardedInterstitial",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to load rewarded-interstitial ad"]
                )
                self.emit(AMBEvents.adLoadFail, err)
                ctx.reject(err)
                return
            }

            self.mAd = interstitialAd
            interstitialAd.fullScreenContentDelegate = self
            interstitialAd.serverSideVerificationOptions = ctx.optGADServerSideVerificationOptions()
            self.emit(AMBEvents.adLoad)
            ctx.resolve()
        }
    }

    override func show(_ ctx: AMBContext) {
        guard let ad = mAd else {
            ctx.reject("Rewarded-interstitial ad not ready")
            return
        }

        // Use the renamed present(from:) API with closure
        ad.present(from: plugin.viewController) {
            let reward = ad.adReward
            self.emit(AMBEvents.adReward, reward)
        }
        ctx.resolve()
    }

    // MARK: — FullScreenContentDelegate callbacks

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

    // MARK: — Helpers

    private func clear() {
        mAd?.fullScreenContentDelegate = nil
        mAd = nil
    }
}
