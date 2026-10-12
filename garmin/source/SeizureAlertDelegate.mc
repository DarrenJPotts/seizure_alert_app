using Toybox.System;
using Toybox.WatchUi;

class SeizureAlertDelegate extends WatchUi.BehaviorDelegate {
    var view;

    function initialize(targetView) {
        BehaviorDelegate.initialize();
        view = targetView;
    }

    function onKey(event) {
        var key = event.getKey();
        if (view.state.equals("pairing")) {
            if (key == WatchUi.KEY_UP) { view.changePairingDigit(1); return true; }
            if (key == WatchUi.KEY_DOWN) { view.changePairingDigit(-1); return true; }
            if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) { view.acceptPairingDigit(); return true; }
            return false;
        }
        if (view.state.equals("countdown")) {
            if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) { view.sendSos(); return true; }
            if (key == WatchUi.KEY_ESC) { view.cancelCountdown(); return true; }
            return true;
        }
        if (key == WatchUi.KEY_ENTER || key == WatchUi.KEY_START) {
            showActions();
            return true;
        }
        return false;
    }

    function onTap(clickEvent) {
        showActions();
        return true;
    }

    function showActions() {
        var menu = new WatchUi.Menu2({ :title => "Safety actions" });
        if (view.state.equals("sos")) {
            menu.addItem(new WatchUi.MenuItem("Cancel SOS", null, "cancel", null));
        } else if (view.state.equals("headsUp")) {
            menu.addItem(new WatchUi.MenuItem("I'm safe", null, "checkIn", null));
        } else {
            menu.addItem(new WatchUi.MenuItem("Send SOS", null, "sos", null));
            menu.addItem(new WatchUi.MenuItem("Heads Up 30 min", null, "heads30", null));
            menu.addItem(new WatchUi.MenuItem("Heads Up 60 min", null, "heads60", null));
            menu.addItem(new WatchUi.MenuItem("Heads Up 120 min", null, "heads120", null));
        }
        menu.addItem(new WatchUi.MenuItem("Refresh", null, "refresh", null));
        WatchUi.pushView(menu, new SeizureAlertMenuDelegate(view), WatchUi.SLIDE_UP);
    }
}

class SeizureAlertMenuDelegate extends WatchUi.Menu2InputDelegate {
    var view;

    function initialize(targetView) {
        Menu2InputDelegate.initialize();
        view = targetView;
    }

    function onSelect(item) {
        var id = item.getId();
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        if (id.equals("sos")) { view.startSosCountdown(); }
        else if (id.equals("cancel")) { view.performAction("cancel", { :alertId => view.alertId }); }
        else if (id.equals("checkIn")) { view.performAction("checkIn", { :headsUpId => view.headsUpId }); }
        else if (id.equals("heads30")) { view.performAction("headsUp", { :durationMinutes => 30 }); }
        else if (id.equals("heads60")) { view.performAction("headsUp", { :durationMinutes => 60 }); }
        else if (id.equals("heads120")) { view.performAction("headsUp", { :durationMinutes => 120 }); }
        else { view.refreshStatus(); }
    }
}
