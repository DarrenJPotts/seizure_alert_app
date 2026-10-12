using Toybox.Application.Storage;
using Toybox.Communications;
using Toybox.System;

module SeizureAlertApi {
    const BASE_URL = "https://us-central1-seizure-alert-app.cloudfunctions.net/";
    var pairCallback = null;

    function isPaired() {
        return Storage.getValue("token") != null;
    }

    function pair(code, callback) {
        pairCallback = callback;
        var options = {
            :method => Communications.HTTP_REQUEST_METHOD_POST,
            :headers => { "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(
            BASE_URL + "wearablePair",
            { :code => code, :deviceName => "Garmin watch" },
            options,
            method(:onPairResponse)
        );
    }

    function onPairResponse(code, data) {
        if (code == 200 && data != null && data[:token] != null) {
            Storage.setValue("token", data[:token]);
            Storage.setValue("deviceId", data[:deviceId]);
        }
        if (pairCallback != null) { pairCallback.invoke(code, data); }
        pairCallback = null;
    }

    function status(callback) {
        request("wearableStatus", Communications.HTTP_REQUEST_METHOD_POST, {}, callback);
    }

    function action(actionName, values, callback) {
        var body = { :action => actionName };
        if (values != null) {
            foreach (var key in values.keys()) {
                body[key] = values[key];
            }
        }
        request("wearableAction", Communications.HTTP_REQUEST_METHOD_POST, body, callback);
    }

    function request(path, methodValue, body, callback) {
        var token = Storage.getValue("token");
        if (token == null) {
            callback.invoke(401, null);
            return;
        }
        var stats = System.getSystemStats();
        body[:batteryPercent] = stats.battery;
        var options = {
            :method => methodValue,
            :headers => {
                "Authorization" => "Bearer " + token,
                "Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON
            },
            :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(
            BASE_URL + path,
            body,
            options,
            callback
        );
    }
}
