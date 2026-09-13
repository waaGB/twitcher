import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Position;
import Toybox.Communications;
import Toybox.PersistedContent;
import Toybox.Timer;
import Toybox.Math;
import Toybox.Application;
import Toybox.System;

class TwitcherView extends WatchUi.View {

    const CAP = 24;
    const MAX_TRIES = 12;

    const TEAL       = 0x005555;
    const ORANGE     = 0xAA5500;
    const TEAL_MUTE  = 0x66BBBB;
    const AMBER_MUTE = 0xFFBB66;

    const EASE = 0.18;

    hidden var rowText = new [24];
    hidden var rowIcon = new [24];
    hidden var rowKind = new [24];
    hidden var rows = 0;

    hidden var nearby = new [12];
    hidden var nearbyN = 0;

    hidden var status = "Locating...";
    hidden var timer = null;
    hidden var done = false;
    hidden var art = null;
    hidden var lastLat = null;
    hidden var lastLng = null;
    hidden var scroll = 0;
    hidden var visible = 5;
    hidden var tries = 0;
    hidden var colourMode = true;

    hidden var colourT = 0.0;
    hidden var fadeTimer = null;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
        art = {};
        art.put("gull", WatchUi.loadResource(Rez.Drawables.IconGull));
        art.put("duck", WatchUi.loadResource(Rez.Drawables.IconDuck));
        art.put("wader", WatchUi.loadResource(Rez.Drawables.IconWader));
        art.put("passerine", WatchUi.loadResource(Rez.Drawables.IconPasserine));
        art.put("corvid", WatchUi.loadResource(Rez.Drawables.IconCorvid));
        art.put("pigeon", WatchUi.loadResource(Rez.Drawables.IconPigeon));
        art.put("raptor", WatchUi.loadResource(Rez.Drawables.IconRaptor));
        art.put("heron", WatchUi.loadResource(Rez.Drawables.IconHeron));
        art.put("bird", WatchUi.loadResource(Rez.Drawables.IconBird));

        colourMode = false;
        try {
            var s = System.getDeviceSettings();
            if (s has :requiresBurnInProtection && s.requiresBurnInProtection == true) {
                colourMode = true;
            }
        } catch (e) {
            colourMode = false;
        }

        var rowH = rowHeight(dc);
        visible = (dc.getHeight() * 0.66).toNumber() / rowH;

        if (visible > 7) {
            visible = 7;
        }
        if (visible < 3) {
            visible = 3;
        }
    }

    hidden function rowHeight(dc) {
        var h = dc.getFontHeight(Graphics.FONT_XTINY) + 6;
        if (h < 32) {
            h = 32;
        }
        return h;
    }

    function onShow() as Void {
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        startTimer();
        fetchNearby();
    }

    hidden function startTimer() {
        tries = 0;
        if (timer != null) {
            timer.stop();
        }
        timer = new Timer.Timer();
        timer.start(method(:tick), 5000, true);
    }

    function onPosition(loc as Position.Info) as Void {
        if (!done) {
            fetchNearby();
        }
    }

    function tick() as Void {
        tries = tries + 1;

        if (tries > MAX_TRIES) {
            if (rows == 0) {
                status = "No GPS. START to retry";
            }
            finish();
            return;
        }

        if (!done) {
            fetchNearby();
        }
    }

    function refresh() as Void {
        rows = 0;
        nearbyN = 0;
        scroll = 0;
        done = false;
        status = "Refreshing...";

        colourT = 0.0;
        stopFade();

        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        startTimer();

        WatchUi.requestUpdate();
        fetchNearby();
    }

    hidden function altStart() {
        for (var i = 0; i < rows; i++) {
            if (rowKind[i].equals("headalt")) {
                return i;
            }
        }
        return -1;
    }

    hidden function altProgress() {
        var alt = altStart();

        if (alt < 0) {
            return 0.0;
        }

        var p = (scroll + visible - alt).toFloat() / visible.toFloat();

        if (p < 0.0) {
            p = 0.0;
        }
        if (p > 1.0) {
            p = 1.0;
        }
        return p;
    }

    hidden function stopFade() {
        if (fadeTimer != null) {
            fadeTimer.stop();
            fadeTimer = null;
        }
    }

    hidden function startFade() {
        if (!colourMode) {
            colourT = altProgress();
            return;
        }

        if (fadeTimer == null) {
            fadeTimer = new Timer.Timer();
            fadeTimer.start(method(:fadeTick), 33, true);
        }
    }

    function fadeTick() as Void {
        var target = altProgress();
        var diff = target - colourT;

        if (diff < 0.004 && diff > -0.004) {
            colourT = target;
            stopFade();
        } else {
            colourT = colourT + (diff * EASE);
        }

        WatchUi.requestUpdate();
    }

    hidden function blend(a, b, t) {
        var ar = (a >> 16) & 0xFF;
        var ag = (a >> 8) & 0xFF;
        var ab = a & 0xFF;

        var br = (b >> 16) & 0xFF;
        var bg = (b >> 8) & 0xFF;
        var bb = b & 0xFF;

        var r = (ar + ((br - ar) * t)).toNumber();
        var g = (ag + ((bg - ag) * t)).toNumber();
        var bl = (ab + ((bb - ab) * t)).toNumber();

        if (r < 0) { r = 0; }
        if (r > 255) { r = 255; }
        if (g < 0) { g = 0; }
        if (g > 255) { g = 255; }
        if (bl < 0) { bl = 0; }
        if (bl > 255) { bl = 255; }

        return (r << 16) | (g << 8) | bl;
    }

    function scrollBy(n) as Void {
        if (rows == 0) {
            return;
        }

        scroll = scroll + n;

        var maxScroll = rows - visible;
        if (maxScroll < 0) {
            maxScroll = 0;
        }
        if (scroll > maxScroll) {
            scroll = maxScroll;
        }
        if (scroll < 0) {
            scroll = 0;
        }

        startFade();
        WatchUi.requestUpdate();
    }

    hidden function prop(key) {
        var v = null;
        try {
            v = Application.Properties.getValue(key);
        } catch (e) {
            v = null;
        }
        return v;
    }

    hidden function cleanKey() {
        var v = prop("apiKey");
        if (v == null) {
            return "";
        }

        var s = v.toString();
        var out = "";

        for (var i = 0; i < s.length(); i++) {
            var c = s.substring(i, i + 1);
            if (!c.equals(" ") && !c.equals("\n") && !c.equals("\r") && !c.equals("\t")) {
                out = out + c;
            }
        }
        return out;
    }

    hidden function num(key, fallback, lo, hi) {
        var v = prop(key);
        var n = fallback;

        if (v != null) {
            try {
                n = v.toNumber();
            } catch (e) {
                n = fallback;
            }
        }

        if (n == null) {
            n = fallback;
        }
        if (n < lo) {
            n = lo;
        }
        if (n > hi) {
            n = hi;
        }
        return n;
    }

    hidden function normalize(name) {
        var n = name.toLower();
        var out = " ";
        for (var i = 0; i < n.length(); i++) {
            var c = n.substring(i, i + 1);
            if (c.equals("-") || c.equals("'") || c.equals("/")) {
                out = out + " ";
            } else {
                out = out + c;
            }
        }
        return out + " ";
    }

    hidden function hasWord(hay, words) {
        for (var i = 0; i < words.size(); i++) {
            if (hay.find(" " + words[i] + " ") != null) {
                return true;
            }
        }
        return false;
    }

    hidden function groupFor(name) {
        var n = normalize(name);

        if (hasWord(n, ["eagle", "hawk", "sparrowhawk", "goshawk", "falcon",
                        "kestrel", "buzzard", "harrier", "kite", "merlin",
                        "osprey", "owl", "peregrine", "hobby", "boobook",
                        "caracara", "vulture", "condor", "kookaburra",
                        "kingfisher"])) {
            return "raptor";
        }
        if (hasWord(n, ["gull", "tern", "kittiwake", "skua", "noddy",
                        "albatross", "petrel", "shearwater", "gannet",
                        "booby", "frigatebird", "jaeger"])) {
            return "gull";
        }
        if (hasWord(n, ["duck", "mallard", "teal", "wigeon", "goose", "swan",
                        "shelduck", "pochard", "gadwall", "shoveler", "eider",
                        "scoter", "merganser", "goosander", "grebe", "coot",
                        "moorhen", "cormorant", "shag", "pintail", "pelican",
                        "swamphen", "gallinule", "darter", "bufflehead",
                        "canvasback", "goldeneye", "loon"])) {
            return "duck";
        }
        if (hasWord(n, ["sandpiper", "plover", "godwit", "curlew", "redshank",
                        "greenshank", "dunlin", "turnstone", "oystercatcher",
                        "avocet", "snipe", "lapwing", "stint", "whimbrel",
                        "sanderling", "ruff", "knot", "stilt", "dowitcher",
                        "yellowlegs", "willet", "killdeer", "phalarope",
                        "dotterel", "tattler"])) {
            return "wader";
        }
        if (hasWord(n, ["heron", "egret", "bittern", "stork", "spoonbill",
                        "crane", "ibis", "brolga", "jabiru"])) {
            return "heron";
        }
        if (hasWord(n, ["crow", "rook", "jackdaw", "magpie", "jay", "raven",
                        "chough", "currawong", "butcherbird", "treepie",
                        "nutcracker"])) {
            return "corvid";
        }
        if (hasWord(n, ["pigeon", "dove", "bronzewing"])) {
            return "pigeon";
        }
        if (hasWord(n, ["warbler", "tit", "finch", "chaffinch", "greenfinch",
                        "goldfinch", "sparrow", "wagtail", "pipit", "thrush",
                        "robin", "wren", "starling", "blackbird", "chat",
                        "bunting", "lark", "skylark", "swallow", "martin",
                        "swift", "dunnock", "goldcrest", "nuthatch",
                        "treecreeper", "flycatcher", "redstart", "wheatear",
                        "shrike", "blackcap", "chiffchaff", "whitethroat",
                        "honeyeater", "fairywren", "thornbill", "silvereye",
                        "friarbird", "wattlebird", "miner", "whistler",
                        "fantail", "gerygone", "scrubwren", "cuckooshrike",
                        "woodswallow", "figbird", "oriole", "cardinal",
                        "chickadee", "junco", "towhee", "vireo", "waxwing",
                        "phoebe", "kinglet", "bushtit", "titmouse",
                        "grackle"])) {
            return "passerine";
        }
        return "bird";
    }

    hidden function request(path, cb) {
        var key = cleanKey();

        if (key.length() < 4) {
            status = "Set API key";
            finish();
            return false;
        }

        var info = Position.getInfo();
        var pos = null;

        if (info != null) {
            pos = info.position;
        }

        if (pos == null) {
            if (rows == 0) {
                status = "Waiting for GPS";
            }
            WatchUi.requestUpdate();
            return false;
        }

        var deg = pos.toDegrees();

        if (deg[0] == 0 && deg[1] == 0) {
            if (rows == 0) {
                status = "Waiting for GPS";
            }
            WatchUi.requestUpdate();
            return false;
        }

        if (deg[0] < -90 || deg[0] > 90 || deg[1] < -180 || deg[1] > 180) {
            if (rows == 0) {
                status = "Waiting for GPS";
            }
            WatchUi.requestUpdate();
            return false;
        }

        lastLat = deg[0];
        lastLng = deg[1];

        var params = {};
        params.put("lat", deg[0].format("%.4f"));
        params.put("lng", deg[1].format("%.4f"));
        params.put("dist", num("searchRadius", 15, 1, 50).format("%d"));
        params.put("back", num("daysBack", 7, 1, 30).format("%d"));
        params.put("maxResults", "10");

        var headers = {};
        headers.put("X-eBirdApiToken", key);

        var options = {};
        options.put(:method, Communications.HTTP_REQUEST_METHOD_GET);
        options.put(:headers, headers);
        options.put(:responseType, Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON);

        Communications.makeWebRequest("https://api.ebird.org/v2/" + path,
            params, options, cb);
        return true;
    }

    function fetchNearby() as Void {
        if (request("data/obs/geo/recent", method(:onNearby))) {
            if (rows == 0) {
                status = "Loading...";
            }
            WatchUi.requestUpdate();
        }
    }

    hidden function collect(data, into, cap) {
        var n = 0;

        if (!(data instanceof Lang.Array)) {
            return 0;
        }

        for (var i = 0; i < data.size(); i++) {
            if (n < cap) {
                var obs = data[i];
                var valid = obs["obsValid"];

                if (valid != null && valid == true) {
                    var name = obs["comName"];

                    if (name != null) {
                        var dup = false;
                        for (var j = 0; j < n; j++) {
                            if (into[j].equals(name)) {
                                dup = true;
                            }
                        }
                        if (!dup) {
                            into[n] = name;
                            n = n + 1;
                        }
                    }
                }
            }
        }
        return n;
    }

    function onNearby(responseCode as Number, data as Null or Dictionary or String or PersistedContent.Iterator) as Void {
        if (responseCode == 200) {
            nearbyN = collect(data, nearby, 12);

            if (nearbyN > 0) {
                build(new [8], 0);
                WatchUi.requestUpdate();
                request("data/obs/geo/recent/notable", method(:onNotable));
            } else {
                status = "No birds";
                finish();
            }
            return;
        }

        if (responseCode == 403) {
            status = "Bad API key";
            finish();
            return;
        }

        if (responseCode == 400) {
            status = "Bad request";
            finish();
            return;
        }

        if (rows == 0) {
            status = "No phone link (" + responseCode + ")";
        }
        WatchUi.requestUpdate();
    }

    function onNotable(responseCode as Number, data as Null or Dictionary or String or PersistedContent.Iterator) as Void {
        var notable = new [8];
        var notableN = 0;

        if (responseCode == 200) {
            notableN = collect(data, notable, 8);
        }

        build(notable, notableN);
        finish();
    }

    hidden function build(notable, notableN) {
        rows = 0;

        if (nearbyN > 0) {
            addRow("NEARBY", null, "head");

            for (var i = 0; i < nearbyN; i++) {
                addRow(nearby[i], groupFor(nearby[i]), "bird");
            }
        }

        if (notableN > 0) {
            addRow("UNUSUAL", null, "headalt");

            for (var i = 0; i < notableN; i++) {
                var dup = false;
                for (var j = 0; j < nearbyN; j++) {
                    if (nearby[j].equals(notable[i])) {
                        dup = true;
                    }
                }
                if (!dup) {
                    addRow(notable[i], groupFor(notable[i]), "birdalt");
                }
            }
        }

        if (rows > 0) {
            status = null;

            if (nearbyN > 0) {
                try {
                    Application.Storage.setValue("lastTop", nearby[0]);
                } catch (e) {
                }
            }

            if (lastLat != null) {
                addRow(lastLat.format("%.3f") + ", " + lastLng.format("%.3f"),
                    null, "foot");
            }
            addRow("eBird / Cornell Lab", null, "foot");
            addRow("START to refresh", null, "foot");
        }
    }

    hidden function addRow(text, icon, kind) {
        if (rows < CAP) {
            rowText[rows] = text;
            rowIcon[rows] = icon;
            rowKind[rows] = kind;
            rows = rows + 1;
        }
    }

    hidden function finish() {
        done = true;
        if (timer != null) {
            timer.stop();
        }
        WatchUi.requestUpdate();
    }

    hidden function fit(dc, text, maxW) {
        if (dc.getTextWidthInPixels(text, Graphics.FONT_XTINY) <= maxW) {
            return text;
        }
        var s = text;
        while (s.length() > 2) {
            s = s.substring(0, s.length() - 1);
            if (dc.getTextWidthInPixels(s + ".", Graphics.FONT_XTINY) <= maxW) {
                return s + ".";
            }
        }
        return s;
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var fh = dc.getFontHeight(Graphics.FONT_XTINY);
        var w = dc.getWidth();

        var muted = Graphics.COLOR_DK_GRAY;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        if (colourMode) {
            muted = blend(TEAL_MUTE, AMBER_MUTE, colourT);

            dc.setColor(blend(TEAL, ORANGE, colourT), Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(cx, cy, cx + 2);
        }

        if (rows == 0) {
            var msg = status;
            if (msg == null) {
                msg = "...";
            }
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy, Graphics.FONT_XTINY, msg,
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(colourMode ? TEAL_MUTE : Graphics.COLOR_DK_GRAY,
                Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, cy + fh + 12, Graphics.FONT_XTINY,
                "eBird / Cornell Lab", Graphics.TEXT_JUSTIFY_CENTER);
            return;
        }

        var rowH = rowHeight(dc);
        var shown = visible;
        if (shown > rows) {
            shown = rows;
        }

        var startY = cy - ((shown * rowH) / 2);
        var r = cx - 6;

        for (var i = 0; i < shown; i++) {
            var idx = scroll + i;
            if (idx >= rows) {
                break;
            }

            var y = startY + (i * rowH);

            var dyTop = (y - cy).abs();
            var dyBot = (y + rowH - cy).abs();
            var dy = dyTop > dyBot ? dyTop : dyBot;

            var half = 0;
            if (dy < r) {
                half = Math.sqrt((r * r) - (dy * dy)).toNumber();
            }

            var left = cx - half;

            if (half < 20) {
                continue;
            }

            var kind = rowKind[idx];

            if (kind.equals("foot")) {
                dc.setColor(muted, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y + 3, Graphics.FONT_XTINY, rowText[idx],
                    Graphics.TEXT_JUSTIFY_CENTER);

            } else if (kind.equals("headalt") && !colourMode) {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(cx - (half / 2), y + 2, half, 1);
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y + 6, Graphics.FONT_XTINY, rowText[idx],
                    Graphics.TEXT_JUSTIFY_CENTER);

            } else if (kind.equals("head") || kind.equals("headalt")) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, y + 3, Graphics.FONT_XTINY, rowText[idx],
                    Graphics.TEXT_JUSTIFY_CENTER);

            } else {
                var textX = left + 36;
                var maxW = (cx + half) - textX;

                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

                var bmp = art.get(rowIcon[idx]);
                if (bmp != null) {
                    dc.drawBitmap(left, y + 1, bmp);
                }

                dc.drawText(textX, y + 3, Graphics.FONT_XTINY,
                    fit(dc, rowText[idx], maxW), Graphics.TEXT_JUSTIFY_LEFT);
            }
        }

        if (rows > visible) {
            var arcR = cx - 4;
            var span = 70;
            var top = span / 2;
            
            var frac = visible.toFloat() / rows.toFloat();
            var thumbSpan = (span * frac).toNumber();
            if (thumbSpan < 8) {
                thumbSpan = 8;
            }

            var pos = scroll.toFloat() / (rows - visible).toFloat();
            var thumbStart = top - ((span - thumbSpan) * pos).toNumber();

            dc.setPenWidth(4);

            dc.setColor(colourMode ? muted : Graphics.COLOR_DK_GRAY,
                Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, arcR, Graphics.ARC_CLOCKWISE,
                top, top - span);

            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawArc(cx, cy, arcR, Graphics.ARC_CLOCKWISE,
                thumbStart, thumbStart - thumbSpan);

            dc.setPenWidth(1);
        }
    }

    function onHide() as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        stopFade();
        if (timer != null) {
            timer.stop();
        }
    }
}