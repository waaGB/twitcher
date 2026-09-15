import Toybox.WatchUi;
import Toybox.Lang;

class TwitcherDelegate extends WatchUi.BehaviorDelegate {

    hidden var view;

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onNextPage() as Boolean {
        view.moveSel(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        view.moveSel(-1);
        return true;
    }

    function onSelect() as Boolean {
        view.openDetail();
        return true;
    }

    function onBack() as Boolean {
        return view.closeDetail();
    }

    function onMenu() as Boolean {
        view.refresh();
        return true;
    }
}