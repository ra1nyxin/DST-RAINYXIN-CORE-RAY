local _G = _G
local Class = _G.Class
local Widget = require("widgets/widget")
local Text = require("widgets/text")

local UPDATE_INTERVAL = 0.5
local LEFT_MARGIN = 32
local TOP_MARGIN = 12
local MINIMAP_GAP = 20
local LINE_HEIGHT = 19
local FONT_SIZE = 18
local TITLE_FONT_SIZE = 20
local MAX_NAME_CHARS = 24
local MAX_NAME_BYTES = 72
local MAX_LINE_WIDTH = 420
local TEXT_LEFT_X = MAX_LINE_WIDTH * 0.5

local LATENCY_COLORS = {
    good = { 0.35, 1.0, 0.45, 0.95 },
    okay = { 0.82, 1.0, 0.40, 0.95 },
    warn = { 1.0, 0.82, 0.35, 0.95 },
    bad = { 1.0, 0.38, 0.38, 0.95 },
    unknown = { 0.82, 0.82, 0.82, 0.95 },
}

local INVISIBLE_MARKERS = {
    string.char(239, 187, 191),
    string.char(194, 173),
    string.char(225, 160, 142),
    string.char(226, 128, 139),
    string.char(226, 128, 140),
    string.char(226, 128, 141),
    string.char(226, 128, 142),
    string.char(226, 128, 143),
    string.char(226, 128, 170),
    string.char(226, 128, 171),
    string.char(226, 128, 172),
    string.char(226, 128, 173),
    string.char(226, 128, 174),
    string.char(226, 129, 160),
    string.char(226, 129, 166),
    string.char(226, 129, 167),
    string.char(226, 129, 168),
    string.char(226, 129, 169),
}

local LATENCY_KEYS = {
    "ping",
    "latency",
    "latency_ms",
    "latencyms",
    "ping_ms",
    "pingms",
    "avgping",
    "averageping",
    "average_ping",
    "ms",
}

local function Utf8CharLength(byte)
    if byte == nil then
        return 1
    elseif byte < 128 then
        return 1
    elseif byte < 224 then
        return 2
    elseif byte < 240 then
        return 3
    elseif byte < 248 then
        return 4
    end
    return 1
end

local function Utf8SafeTruncate(str, max_chars, max_bytes)
    local limit_chars = max_chars or MAX_NAME_CHARS
    local limit_bytes = max_bytes or MAX_NAME_BYTES
    local i = 1
    local char_count = 0
    local byte_count = 0
    local total_bytes = #str

    while i <= total_bytes and char_count < limit_chars and byte_count < limit_bytes do
        local char_len = Utf8CharLength(str:byte(i))
        if i + char_len - 1 > total_bytes or byte_count + char_len > limit_bytes then
            break
        end
        i = i + char_len
        byte_count = byte_count + char_len
        char_count = char_count + 1
    end

    if i > total_bytes then
        return str
    end

    return str:sub(1, i - 1) .. "..."
end

local function CollapseWhitespace(str)
    str = str:gsub("%s+", " ")
    str = str:match("^%s*(.-)%s*$") or ""
    return str
end

local function SanitizePlayerName(name)
    local sanitized = type(name) == "string" and name or tostring(name or "")
    sanitized = sanitized:gsub("[%z\1-\31\127]", " ")

    for _, marker in ipairs(INVISIBLE_MARKERS) do
        sanitized = sanitized:gsub(marker, "")
    end

    sanitized = sanitized:gsub("[<>\"'`%%]", " ")
    sanitized = CollapseWhitespace(sanitized)

    if sanitized == "" then
        sanitized = "?"
    end

    return Utf8SafeTruncate(sanitized, MAX_NAME_CHARS, MAX_NAME_BYTES)
end

local function ClampLatency(value)
    if type(value) ~= "number" then
        return nil
    end
    if value ~= value or value < 0 or value == math.huge or value == -math.huge then
        return nil
    end
    return math.floor(value + 0.5)
end

local function ReadLatencyValue(record)
    if type(record) ~= "table" then
        return nil
    end

    for _, key in ipairs(LATENCY_KEYS) do
        local value = record[key]
        if type(value) == "string" then
            value = tonumber(value)
        end
        value = ClampLatency(value)
        if value ~= nil then
            return value
        end
    end

    return nil
end

local function GetLatencyColor(latency_ms, netscore)
    if latency_ms ~= nil then
        if latency_ms <= 80 then
            return LATENCY_COLORS.good
        elseif latency_ms <= 160 then
            return LATENCY_COLORS.okay
        elseif latency_ms <= 250 then
            return LATENCY_COLORS.warn
        end
        return LATENCY_COLORS.bad
    end

    if type(netscore) == "number" then
        if netscore <= 0 then
            return LATENCY_COLORS.okay
        elseif netscore == 1 then
            return LATENCY_COLORS.warn
        end
        return LATENCY_COLORS.bad
    end

    return LATENCY_COLORS.unknown
end

local function FormatLatencyText(latency_ms)
    if latency_ms == nil then
        return "-- ms"
    end
    return string.format("%d ms", latency_ms)
end

local function GetFallbackLocalName()
    if _G.ThePlayer ~= nil and type(_G.ThePlayer.name) == "string" and _G.ThePlayer.name ~= "" then
        return SanitizePlayerName(_G.ThePlayer.name)
    end
    return "我"
end

local PlayerLatencyWidget = Class(Widget, function(self, owner, controls)
    Widget._ctor(self, "PlayerLatencyWidget")

    self.owner = owner
    self.controls = controls
    self.elapsed = 0
    self.labels = {}
    self.title = self:AddChild(Text(_G.CHATFONT, TITLE_FONT_SIZE, "在线玩家"))
    self.title:SetRegionSize(MAX_LINE_WIDTH, LINE_HEIGHT)
    self.title:SetHAlign(_G.ANCHOR_LEFT)
    self.title:SetColour(1, 1, 1, 0.95)
    self.title:SetPosition(TEXT_LEFT_X, 0, 0)

    self:SetPosition(LEFT_MARGIN, -TOP_MARGIN, 0)
    self:StartUpdating()
end)

function PlayerLatencyWidget:RefreshAnchorPosition()
    local x = LEFT_MARGIN
    local y = -TOP_MARGIN

    if self.controls ~= nil and self.controls.minimap_small ~= nil and self.controls.minimap_small.mapsize ~= nil and _G.TheSim ~= nil then
        local hudscale = self.controls.top_root ~= nil and self.controls.top_root:GetScale() or nil
        local screenw, screenh = _G.TheSim:GetScreenSize()
        if hudscale ~= nil and hudscale.x ~= nil and hudscale.x ~= 0 and hudscale.y ~= nil and hudscale.y ~= 0 then
            screenw = screenw / hudscale.x
            screenh = screenh / hudscale.y
        end

        local mapx, mapy = self.controls.minimap_small:GetPosition():Get()
        local mapw = self.controls.minimap_small.mapsize.w or 0
        local maph = self.controls.minimap_small.mapsize.h or 0
        local map_left = screenw * 0.5 + mapx - mapw * 0.5
        local map_right = screenw * 0.5 + mapx + mapw * 0.5
        local map_top = mapy - maph * 0.5
        local map_bottom = mapy + maph * 0.5

        if map_left <= LEFT_MARGIN + 8 and map_right > LEFT_MARGIN and map_top <= 8 and map_bottom > -80 then
            x = math.floor(map_right + MINIMAP_GAP)
        end
    end

    self:SetPosition(x, y, 0)
end

function PlayerLatencyWidget:HideAll()
    for i = 1, #self.labels do
        self.labels[i]:Hide()
    end
end

function PlayerLatencyWidget:EnsureLabelCount(count)
    while #self.labels < count do
        local label = self:AddChild(Text(_G.CHATFONT, FONT_SIZE, ""))
        label:SetRegionSize(MAX_LINE_WIDTH, LINE_HEIGHT)
        label:SetHAlign(_G.ANCHOR_LEFT)
        label:Hide()
        self.labels[#self.labels + 1] = label
    end
end

function PlayerLatencyWidget:GetLatencyMs(record)
    local local_userid = _G.TheNet ~= nil and _G.TheNet:GetUserID() or nil
    if record ~= nil and local_userid ~= nil and record.userid == local_userid and _G.TheNet.GetAveragePing ~= nil then
        return ClampLatency(_G.TheNet:GetAveragePing())
    end

    local latency_ms = ReadLatencyValue(record)
    if latency_ms ~= nil then
        return latency_ms
    end

    if _G.TheNet ~= nil and _G.TheNet.GetClientTableForUser ~= nil and record ~= nil and record.userid ~= nil then
        return ReadLatencyValue(_G.TheNet:GetClientTableForUser(record.userid))
    end

    return nil
end

function PlayerLatencyWidget:GetDisplayClients()
    local local_name = GetFallbackLocalName()
    local local_userid = _G.TheNet ~= nil and _G.TheNet:GetUserID() or nil
    local local_latency = _G.TheNet ~= nil and _G.TheNet.GetAveragePing ~= nil and ClampLatency(_G.TheNet:GetAveragePing()) or nil

    if _G.TheNet == nil or _G.TheNet.GetClientTable == nil then
        return {
            {
                userid = local_userid,
                name = local_name,
                latency_ms = local_latency,
                netscore = nil,
                is_local = true,
            }
        }
    end

    local raw_clients = _G.TheNet:GetClientTable()
    if raw_clients == nil then
        return {
            {
                userid = local_userid,
                name = local_name,
                latency_ms = local_latency,
                netscore = nil,
                is_local = true,
            }
        }
    end

    local hosted = _G.TheNet:GetServerIsClientHosted()
    local clients = {}

    for _, client in ipairs(raw_clients) do
        if type(client) == "table" then
            if hosted or client.performance == nil then
                clients[#clients + 1] = {
                    userid = client.userid,
                    name = SanitizePlayerName(client.name),
                    latency_ms = self:GetLatencyMs(client),
                    netscore = client.netscore,
                    is_local = client.userid ~= nil and client.userid == local_userid,
                }
            end
        end
    end

    table.sort(clients, function(a, b)
        if a.is_local ~= b.is_local then
            return a.is_local
        elseif a.name == b.name then
            return (a.userid or "") < (b.userid or "")
        end
        return a.name < b.name
    end)

    if #clients == 0 then
        clients[1] = {
            userid = local_userid,
            name = local_name,
            latency_ms = local_latency,
            netscore = nil,
            is_local = true,
        }
    end

    return clients
end

function PlayerLatencyWidget:Refresh()
    self:RefreshAnchorPosition()

    local clients = self:GetDisplayClients()
    self:EnsureLabelCount(#clients)

    for i = 1, #clients do
        local client = clients[i]
        local label = self.labels[i]
        local color = GetLatencyColor(client.latency_ms, client.netscore)
        local line = string.format("%s  %s", client.name, FormatLatencyText(client.latency_ms))

        label:SetString(line)
        label:SetColour(color[1], color[2], color[3], color[4])
        label:SetPosition(TEXT_LEFT_X, -(i * LINE_HEIGHT + 6), 0)
        label:Show()
    end

    for i = #clients + 1, #self.labels do
        self.labels[i]:Hide()
    end
end

function PlayerLatencyWidget:OnUpdate(dt)
    self.elapsed = self.elapsed + dt
    if self.elapsed < UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self:Refresh()
end

return PlayerLatencyWidget
