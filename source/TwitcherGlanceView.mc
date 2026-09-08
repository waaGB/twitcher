import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;

(:glance)
class TwitcherGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var top = "Twitcher";
        var bottom = "Open for nearby birds";

        var stored = null;
        try {
            stored = Application.Storage.getValue("lastTop");
        } catch (e) {
            stored = null;
        }

        if (stored != null) {
            bottom = stored.toString();
        }

        var fh = dc.getFontHeight(Graphics.FONT_XTINY);
        var cy = dc.getHeight() / 2;

        dc.drawText(4, cy - fh, Graphics.FONT_XTINY, top,
            Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawText(4, cy, Graphics.FONT_XTINY, bottom,
            Graphics.TEXT_JUSTIFY_LEFT);
    }
}