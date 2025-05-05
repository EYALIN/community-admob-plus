package cordova.plugin.consent;

import android.util.Log;
import android.util.SparseArray;

import com.google.android.ump.ConsentForm;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.UserMessagingPlatform;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;

import cordova.plugin.consent.Generated.Actions;
import cordova.plugin.consent.Generated.ConsentStatus;

public class Consent extends CordovaPlugin {
    private static final SparseArray<ConsentForm> forms = new SparseArray<>();
    private final ArrayList<PluginResult> eventQueue = new ArrayList<>();
    private final String TAG = this.getClass().getSimpleName();
    private CallbackContext readyCallbackContext = null;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        ExecuteContext.plugin = this;
    }

    @Override
    public boolean execute(String actionKey, JSONArray args, final CallbackContext callbackContext) {
        ExecuteContext ctx = new ExecuteContext(actionKey, args, callbackContext);
        Log.d(TAG, actionKey);

        switch (actionKey) {
            case Actions.READY:
                return executeReady(callbackContext);
            case Actions.GET_CONSENT_STATUS:
                callbackContext.success(getConsentStatus());
                break;
            case Actions.GET_FORM_STATUS:
                callbackContext.success(getConsentInformation().isConsentFormAvailable() ? 1 : 2);
                break;
            case Actions.REQUEST_INFO_UPDATE:
                return executeRequestInfoUpdate(ctx);
            case Actions.LOAD_FORM:
                return executeLoadForm(ctx);
            case Actions.SHOW_FORM:
                return executeShowForm(ctx);
            case Actions.RESET:
                getConsentInformation().reset();
                callbackContext.success();
                break;
            case Actions.PRIVACY_OPTIONS_REQUIREMENT_STATUS:
                return executePrivacyOptionsRequirementStatus(ctx);
            case Actions.CAN_REQUEST_ADS:
                return executeCanRequestAds(ctx);
            case Actions.LOAD_AND_SHOW_IF_REQUIRED:
                return executeLoadAndShowIfRequired(ctx);
            case Actions.SHOW_PRIVACY_OPTIONS_FORM:
                return executeShowPrivacyOptionsForm(ctx);
            default:
                return false;
        }

        return true;
    }

    private int getConsentStatus() {
        int status = getConsentInformation().getConsentStatus();
        switch (status) {
            case ConsentInformation.ConsentStatus.NOT_REQUIRED:
                return ConsentStatus.NOT_REQUIRED;
            case ConsentInformation.ConsentStatus.REQUIRED:
                return ConsentStatus.REQUIRED;
            default:
                return status;
        }
    }

    private boolean executeReady(CallbackContext callbackContext) {
        if (readyCallbackContext == null) {
            for (PluginResult result : eventQueue) {
                callbackContext.sendPluginResult(result);
            }
            eventQueue.clear();
        } else {
            Log.e(TAG, "Ready action should only be called once.");
        }
        readyCallbackContext = callbackContext;
        emit(Generated.Events.READY);
        return true;
    }

    private boolean executeRequestInfoUpdate(ExecuteContext ctx) {
        ConsentRequestParameters params = ctx.optConsentRequestParameters();
        ConsentInformation consentInformation = getConsentInformation();
        consentInformation.requestConsentInfoUpdate(
                cordova.getActivity(),
                params,
                ctx.callbackContext::success,
                formError -> ctx.callbackContext.error(formError.getMessage())
        );
        return true;
    }

    private boolean executePrivacyOptionsRequirementStatus(ExecuteContext ctx) {
        ConsentInformation consentInformation = getConsentInformation();
        String status = consentInformation.getPrivacyOptionsRequirementStatus().name();
        Log.d(TAG, "privacy status: " + status);
        ctx.callbackContext.success(status);
        return true;
    }

    private boolean executeCanRequestAds(ExecuteContext ctx) {
        ConsentInformation consentInformation = getConsentInformation();
        String result = String.valueOf(consentInformation.canRequestAds());
        ctx.callbackContext.success(result);
        return true;
    }

    private boolean executeLoadAndShowIfRequired(ExecuteContext ctx) {
        cordova.getActivity().runOnUiThread(() -> {
            UserMessagingPlatform.loadAndShowConsentFormIfRequired(
                cordova.getActivity(),
                formError -> {
                    if (formError != null) {
                        ctx.callbackContext.error(formError.getErrorCode() + " " + formError.getMessage());
                    } else {
                        ctx.callbackContext.success("success");
                    }
                }
            );
        });
        return true;
    }



    private boolean executeShowPrivacyOptionsForm(ExecuteContext ctx) {
        cordova.getActivity().runOnUiThread(() -> {
            UserMessagingPlatform.showPrivacyOptionsForm(
                    cordova.getActivity(),
                    formError -> {
                        if (formError != null) {
                            ctx.callbackContext.error(formError.getErrorCode() + " " + formError.getMessage());
                        } else {
                            ctx.callbackContext.success("success");
                        }
                    }
            );
        });
        return true;
    }

    private boolean executeLoadForm(ExecuteContext ctx) {
        cordova.getActivity().runOnUiThread(() -> {
            UserMessagingPlatform.loadConsentForm(
                cordova.getActivity(),
                consentForm -> {
                    int id = consentForm.hashCode();
                    forms.put(id, consentForm);
                    ctx.callbackContext.success(id);
                },
                formError -> {
                    if (formError != null) {
                        ctx.callbackContext.error(formError.getErrorCode() + " " + formError.getMessage());
                    }
                }
            );
        });
        return true;
    }

    private boolean executeShowForm(ExecuteContext ctx) {
        final ConsentForm consentForm = forms.get(ctx.optId());
        if (consentForm == null) {
            ctx.callbackContext.error("Consent form not found or already used.");
            return true;
        }

        cordova.getActivity().runOnUiThread(() -> {
            consentForm.show(
                    cordova.getActivity(),
                    formError -> {
                        forms.remove(ctx.optId());
                        if (formError == null) {
                            ctx.callbackContext.success();
                        } else {
                            ctx.callbackContext.error(formError.getErrorCode() + " " + formError.getMessage());
                        }
                    });
        });
        return true;
    }

    private ConsentInformation getConsentInformation() {
        return UserMessagingPlatform.getConsentInformation(cordova.getActivity());
    }

    @Override
    public void onDestroy() {
        readyCallbackContext = null;
        super.onDestroy();
    }

    public void emit(String eventType) {
        emit(eventType, null);
    }

    public void emit(String eventType, Object data) {
        JSONObject event = new JSONObject();
        try {
            event.put("type", eventType);
            event.put("data", data);
        } catch (JSONException e) {
            e.printStackTrace();
        }

        PluginResult result = new PluginResult(PluginResult.Status.OK, event);
        result.setKeepCallback(true);
        if (readyCallbackContext == null) {
            eventQueue.add(result);
        } else {
            readyCallbackContext.sendPluginResult(result);
        }
    }
}
