name = "DST-RAINYXIN-CORE-RAY"
description = [[
Client-only survival helper utilities focused on guidance, convenience, and lower-friction play.

Current features:
- Nearby flowers, butterflies, players, and Touch Stones are highlighted with local text indicators around your character.
- Adds a top-left player list with per-player latency text and color-coded delay levels.
- Adds an experimental client-side interaction reach increase for pickup, pick, harvest, mine, dig, and chop actions.
- Adds an experimental client-side faster-attack tweak that tries to send and recycle real attack inputs earlier.
- The indicators are rendered only on your own client.
- The server and host do not need to install this mod.
- The guidance scans a large area, keeps distance text, and now shows all detected labels without angle-based priority filtering.
- Player names in the latency list are sanitized before drawing to avoid control-character, bidi, zero-width, and overlong-name UI problems.
- The interaction reach tweak is also experimental and mainly intended to probe how far client-side action distance changes can still be accepted by the server.
- The faster-attack tweak is another sync-boundary experiment and may still be limited by server-side combat timing.
- The earlier `1.1x` and `1.05x` movement-speed experiments were removed after repeated rubber-banding tests showed that movement sync is enforced too tightly.
- Adds a Pig King direction label that can keep pointing toward the Pig King from far away by reading client-side world topology and keeping the inferred location in memory only for the current session.
- Pig King and discovered Touch Stones now use memory-only cached world positions so their direction and distance labels can keep working anywhere on the map during the current play session.
]]
author = "ra1nyxin"
version = "0.1.26"

forumthread = ""
api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = false
client_only_mod = true

icon_atlas = nil
icon = nil

server_filter_tags = {
    "client",
    "helper",
    "flower",
    "butterfly",
    "player",
    "guide",
    "latency",
    "ping",
    "list",
    "reach",
    "attack",
    "touch stone",
    "pig king",
}
