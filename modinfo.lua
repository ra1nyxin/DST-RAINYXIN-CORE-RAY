name = "DST-RAINYXIN-CORE-RAY"
description = [[
Client-only survival helper utilities focused on guidance, convenience, and lower-friction play.

Current features:
- Nearby flowers, butterflies, players, and Touch Stones are highlighted with local text indicators around your character.
- Adds a local predicted `1.1x` movement speed boost for your own client-side player movement.
- Adds an experimental client-side interaction reach increase for pickup, pick, harvest, mine, dig, and chop actions.
- The indicators are rendered only on your own client.
- The server and host do not need to install this mod.
- The guidance scans a large area, keeps distance text, and now shows all detected labels without angle-based priority filtering.
- The speed boost is client-side prediction only and does not rewrite server-authoritative movement.
- The interaction reach tweak is also experimental and mainly intended to probe how far client-side action distance changes can still be accepted by the server.
]]
author = "ra1nyxin"
version = "0.1.11"

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
    "speed",
    "reach",
    "touch stone",
}
