#if canImport(AppTrackingTransparency)
import AppTrackingTransparency
#endif
import UserMessagingPlatform

@objc(CSNConsent)
class CSNConsent: CDVPlugin {
    var readyCallbackId: String!

    override func pluginInitialize() {
        super.pluginInitialize()
        CSNContext.plugin = self
    }

    deinit {
        readyCallbackId = nil
        CSNContext.plugin = nil
    }

    @objc func ready(_ command: CDVInvokedUrlCommand) {
        readyCallbackId = command.callbackId
        self.emit(eventType: CSNEvents.ready)
    }

    @objc func canRequestAds(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)
        ctx.success(ConsentInformation.shared.canRequestAds)
    }

    @objc func privacyOptionsRequirementStatus(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)
        ctx.success(ConsentInformation.shared.privacyOptionsRequirementStatus.rawValue)
    }

    @objc func loadAndShowIfRequired(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)
        ConsentForm.loadAndPresentIfRequired(from: self.viewController) { [weak self] loadAndPresentError in
            guard self != nil else {
                return ctx.success()
            }

            if let consentError = loadAndPresentError {
                ctx.error(consentError)
                return
            }

            ctx.success()
        }
    }

    @objc func showPrivacyOptionsForm(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)
        ConsentForm.presentPrivacyOptionsForm(from: self.viewController) { [weak self] formError in
            guard self != nil, formError == nil else {
                ctx.error(formError)
                return
            }
            ctx.success()
        }
    }

    @objc func trackingAuthorizationStatus(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)

        if #available(iOS 14, *) {
            ctx.success(ATTrackingManager.trackingAuthorizationStatus.rawValue)
        } else {
            ctx.success(false)
        }
    }

    @objc func requestTrackingAuthorization(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)

        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                ctx.success(status.rawValue)
            }
        } else {
            ctx.success(false)
        }
    }

    @objc func requestInfoUpdate(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)

        ConsentInformation.shared.requestConsentInfoUpdate(
            with: ctx.optRequestParameters(),
            completionHandler: { error in
                if let error = error {
                    ctx.error(error)
                } else {
                    ctx.success()
                }
            }
        )
    }

    @objc func getFormStatus(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)
        ctx.success(ConsentInformation.shared.formStatus.rawValue)
    }

    @objc func getConsentStatus(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)
        ctx.success(ConsentInformation.shared.consentStatus.rawValue)
    }

    @objc func loadForm(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)

        ConsentForm.load { form, loadError in
            if let loadError = loadError {
                ctx.error(loadError)
            } else if let form = form {
                let id = form.hashValue % (2 << 30)
                CSNContext.forms[id] = form
                ctx.success(id)
            } else {
                ctx.error("Consent form is nil")
            }
        }
    }

    @objc func showForm(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)

        if let form = ctx.optForm() {
            form.present(from: self.viewController) { dismissError in
                if let dismissError = dismissError {
                    ctx.error(dismissError)
                } else {
                    ctx.success()
                }
            }
        } else {
            ctx.error("Form not found")
        }
    }

    @objc func reset(_ command: CDVInvokedUrlCommand) {
        let ctx = CSNContext(command)
        ConsentInformation.shared.reset()
        ctx.success()
    }

    func emit(eventType: String, data: Any = NSNull()) {
        let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: ["type": eventType, "data": data])
        result?.setKeepCallbackAs(true)
        self.commandDelegate.send(result, callbackId: readyCallbackId)
    }
}
