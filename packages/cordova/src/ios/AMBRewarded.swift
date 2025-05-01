import GoogleMobileAds

class AMBRewarded: AMBAdBase, FullScreenContentDelegate {
    private var mAd: RewardedAd?

    deinit {
        clear()
    }

    override func isLoaded() -> Bool {
        return mAd != nil
    }

    override func load(_ ctx: AMBContext) {
        clear()

        // Use the new Swift signature: load(with:request:) { … }
        RewardedAd.load(
            with: adUnitId,
            request: adRequest
        ) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                self.emit(AMBEvents.adLoadFail, error)
                ctx.reject(error)
                return
            }

            guard let rewardedAd = ad else {
                let err = NSError(
                    domain: "AMBRewarded",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to load rewarded ad"]
                )
                self.emit(AMBEvents.adLoadFail, err)
                ctx.reject(err)
                return
            }

            self.mAd = rewardedAd
            rewardedAd.fullScreenContentDelegate = self
            rewardedAd.serverSideVerificationOptions = ctx.optGADServerSideVerificationOptions()
            self.emit(AMBEvents.adLoad)
            ctx.resolve()
        }
    }

    override func show(_ ctx: AMBContext) {
        guard let ad = mAd else {
            ctx.reject("Rewarded ad not ready")
            return
        }

        // Use the new Swift signature: present(from:) { … }
        ad.present(from: plugin.viewController) {
            let reward = ad.adReward
            self.emit(AMBEvents.adReward, reward)
        }
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

    // MARK: - Private Helpers

    private func clear() {
        mAd?.fullScreenContentDelegate = nil
        mAd = nil
    }
}
