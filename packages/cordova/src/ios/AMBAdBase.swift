import GoogleMobileAds

class AMBAdBase: AMBCoreAd {
  func isLoaded() -> Bool {
    #if targetEnvironment(simulator)
    fatalError(AMBCoreError.notImplemented.localizedDescription)
    #else
    return false
    #endif
  }

  func load(_ ctx: AMBContext) {
    ctx.reject(AMBCoreError.notImplemented)
    #if targetEnvironment(simulator)
    fatalError(AMBCoreError.notImplemented.localizedDescription)
    #endif
  }

  func show(_ ctx: AMBContext) {
    ctx.reject(AMBCoreError.notImplemented)
    #if targetEnvironment(simulator)
    fatalError(AMBCoreError.notImplemented.localizedDescription)
    #endif
  }

  func hide(_ ctx: AMBContext) {
    ctx.reject(AMBCoreError.notImplemented)
    #if targetEnvironment(simulator)
    fatalError(AMBCoreError.notImplemented.localizedDescription)
    #endif
  }

  var plugin: AMBPlugin { AMBContext.plugin }

  func emit(_ eventName: String) {
    emit(eventName, ["adId": id])
  }

  func emit(_ eventName: String, _ error: Error) {
    emit(eventName, ["message": error.localizedDescription])
  }

  func emit(_ eventName: String, _ reward: AdReward) {
    emit(eventName, [
      "reward": [
        "amount": reward.amount,
        "type": reward.type
      ]
    ])
  }

  func emit(_ eventName: String, _ adSize: AdSize) {
    emit(eventName, [
      "size": [
        "width": adSize.size.width,
        "height": adSize.size.height
      ]
    ])
  }

  func emit(_ eventName: String, _ data: [String: Any]) {
    // Explicitly make d a [String:Any] so merge(data) works:
    var d: [String: Any] = ["adId": id]
    d.merge(data) { current, _ in current }
    plugin.emit(eventName, data: d)
  }

  func emit(_ eventName: String, _ nativeAd: NativeAd) {
    plugin.emit(eventName, data: ["adId": nativeAd.hashValue])
  }
}
