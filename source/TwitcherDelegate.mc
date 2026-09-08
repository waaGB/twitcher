import Toybox.WatchUi;
import Toybox.Lang;

class TwitcherDelegate extends WatchUi.BehaviorDelegate {

    hidden var view;

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onNextPage() as Boolean {
        view.scrollBy(1);
        return true;
    }

    function onPreviousPage() as Boolean {
        view.scrollBy(-1);
        return true;
    }

    function onSelect() as Boolean {
        view.refresh();
        return true;
    }
}