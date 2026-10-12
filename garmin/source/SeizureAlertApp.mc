using Toybox.Application;
using Toybox.WatchUi;

class SeizureAlertApp extends Application.AppBase {
    function initialize() {
        AppBase.initialize();
    }

    function getInitialView() {
        var view = new SeizureAlertView();
        return [view, new SeizureAlertDelegate(view)];
    }
}
