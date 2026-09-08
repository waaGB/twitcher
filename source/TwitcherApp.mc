import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class TwitcherApp extends Application.AppBase {

    hidden var view = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    (:glance)
    function getGlanceView() {
        return [ new TwitcherGlanceView() ];
    }

    function getInitialView() {
        view = new TwitcherView();
        return [ view, new TwitcherDelegate(view) ];
    }
}