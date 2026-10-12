using Toybox.Attention;
using Toybox.Graphics;
using Toybox.Lang;
using Toybox.Timer;
using Toybox.WatchUi;

class SeizureAlertView extends WatchUi.View {
    var state = "loading";
    var detail = "Checking status";
    var alertId = null;
    var headsUpId = null;
    var pairingDigits = [0, 0, 0, 0, 0, 0];
    var pairingIndex = 0;
    var countdown = 0;
    var countdownTimer = null;

    function onShow() {
        if (!SeizureAlertApi.isPaired()) {
            state = "pairing";
            detail = "Enter the phone code";
            WatchUi.requestUpdate();
            return;
        }
        refreshStatus();
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_WHITE);
        dc.clear();
        var width = dc.getWidth();
        var height = dc.getHeight();
        dc.drawText(width / 2, height * 0.14, Graphics.FONT_XTINY, "SEIZURE ALERT", Graphics.TEXT_JUSTIFY_CENTER);

        if (state.equals("pairing")) {
            drawPairing(dc, width, height);
            return;
        }
        if (state.equals("countdown")) {
            dc.drawText(width / 2, height * 0.38, Graphics.FONT_NUMBER_HOT, countdown.format("%d"), Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, height * 0.64, Graphics.FONT_SMALL, "SELECT sends now", Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(width / 2, height * 0.76, Graphics.FONT_XTINY, "BACK cancels", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var title = state.equals("sos") ? "SOS ACTIVE" : state.equals("headsUp") ? "HEADS UP" : state.equals("ready") ? "READY" : "CHECKING";
        dc.drawText(width / 2, height * 0.38, Graphics.FONT_LARGE, title, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.55, Graphics.FONT_XTINY, detail, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.76, Graphics.FONT_SMALL, "SELECT for actions", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawPairing(dc, width, height) {
        var code = "";
        for (var i = 0; i < pairingDigits.size(); i += 1) {
            code += pairingDigits[i].format("%d");
            if (i == pairingIndex) { code += "_"; }
            if (i < pairingDigits.size() - 1) { code += " "; }
        }
        dc.drawText(width / 2, height * 0.34, Graphics.FONT_MEDIUM, code, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.56, Graphics.FONT_XTINY, "UP/DOWN changes digit", Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(width / 2, height * 0.68, Graphics.FONT_XTINY, "SELECT confirms", Graphics.TEXT_JUSTIFY_CENTER);
    }

    function pairingCode() {
        var value = "";
        foreach (var digit in pairingDigits) { value += digit.format("%d"); }
        return value;
    }

    function changePairingDigit(delta) {
        pairingDigits[pairingIndex] = (pairingDigits[pairingIndex] + delta + 10) % 10;
        WatchUi.requestUpdate();
    }

    function acceptPairingDigit() {
        if (pairingIndex < 5) {
            pairingIndex += 1;
            WatchUi.requestUpdate();
            return;
        }
        state = "loading";
        detail = "Pairing watch";
        WatchUi.requestUpdate();
        SeizureAlertApi.pair(pairingCode(), method(:onPaired));
    }

    function onPaired(code, data) {
        if (code == 200) {
            refreshStatus();
        } else {
            state = "pairing";
            pairingIndex = 0;
            detail = "Code invalid or expired";
            WatchUi.requestUpdate();
        }
    }

    function refreshStatus() {
        state = "loading";
        detail = "Checking status";
        WatchUi.requestUpdate();
        SeizureAlertApi.status(method(:onStatus));
    }

    function onStatus(code, data) {
        if (code == 200 && data != null) {
            state = data[:state];
            alertId = data[:alertId];
            headsUpId = data[:headsUpId];
            detail = state.equals("ready") ? "Alerts available" : "Tap SELECT for actions";
        } else {
            state = "offline";
            detail = "Phone service unavailable";
        }
        WatchUi.requestUpdate();
    }

    function startSosCountdown() {
        state = "countdown";
        countdown = 10;
        Attention.vibrate([new Attention.VibeProfile(80, 500)]);
        countdownTimer = new Timer.Timer();
        countdownTimer.start(method(:countdownTick), 1000, true);
        WatchUi.requestUpdate();
    }

    function countdownTick() {
        countdown -= 1;
        if (countdown <= 0) { sendSos(); }
        WatchUi.requestUpdate();
    }

    function cancelCountdown() {
        if (countdownTimer != null) { countdownTimer.stop(); }
        refreshStatus();
    }

    function sendSos() {
        if (countdownTimer != null) { countdownTimer.stop(); }
        state = "loading";
        detail = "Sending SOS";
        WatchUi.requestUpdate();
        SeizureAlertApi.action("sos", {}, method(:onAction));
    }

    function performAction(name, values) {
        state = "loading";
        detail = "Updating";
        WatchUi.requestUpdate();
        SeizureAlertApi.action(name, values, method(:onAction));
    }

    function onAction(code, data) {
        if (code == 200) {
            Attention.vibrate([new Attention.VibeProfile(120, 800)]);
            refreshStatus();
        } else {
            state = "offline";
            detail = "Action was not sent";
            WatchUi.requestUpdate();
        }
    }
}
