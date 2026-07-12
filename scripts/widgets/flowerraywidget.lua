local _G = _G
local Class = _G.Class
local Widget = require("widgets/widget")
local Text = require("widgets/text")

local UPDATE_INTERVAL = 0.1
local SEARCH_RADIUS = 100
local RING_RADIUS = 104
local PLAYER_SCREEN_Y_OFFSET = 28
local MAX_LABELS = 12
local MIN_ANGLE_SEPARATION = 12 * (_G.DEGREES or (math.pi / 180))
local LABEL_FONT_SIZE = 19
local FLOWER_MUST_TAGS = { "pickable" }
local FLOWER_CANT_TAGS = { "INLIMBO", "NOCLICK", "FX", "DECOR" }
local BUTTERFLY_MUST_TAGS = { "butterfly" }
local BUTTERFLY_CANT_TAGS = { "INLIMBO", "NOCLICK", "FX", "DECOR" }
local PLAYER_MUST_TAGS = { "player" }
local PLAYER_CANT_TAGS = { "INLIMBO", "playerghost", "FX", "DECOR" }
local TOUCHSTONE_MUST_TAGS = { "resurrector" }
local TOUCHSTONE_CANT_TAGS = { "INLIMBO", "NOCLICK", "FX", "DECOR" }
local PLAYER_TARGET = { label = "人", color = { 1, 1, 1, 0.95 } }
local TARGET_PREFABS = {
    flower = { label = "花", color = { 1, 0.95, 0.3, 0.95 } },
    flower_evil = { label = "花", color = { 1, 0.8, 0.3, 0.95 } },
    flower_rose = { label = "花", color = { 1, 0.7, 0.85, 0.95 } },
    butterfly = { label = "蝶", color = { 1, 0.9, 0.45, 0.95 } },
    resurrectionstone = { label = "试金石", color = { 0.7, 0.95, 1, 0.95 } },
}

local TWO_PI = math.pi * 2
local DEGREES = _G.DEGREES or (math.pi / 180)

local function RotateByHeading(dx, dz)
    local heading = 45
    if _G.TheCamera ~= nil then
        if _G.TheCamera.GetHeadingTarget ~= nil then
            heading = _G.TheCamera:GetHeadingTarget()
        elseif _G.TheCamera.GetHeading ~= nil then
            heading = _G.TheCamera:GetHeading()
        end
    end

    local radians = -heading * DEGREES
    local cos_h = math.cos(radians)
    local sin_h = math.sin(radians)
    return dx * cos_h - dz * sin_h, dx * sin_h + dz * cos_h
end

local function ApproximateScreenDelta(dx, dz)
    local rx, rz = RotateByHeading(dx, dz)
    return rx - rz, -(rx + rz) * 0.5
end

local function GetScreenPoint(x, y, z)
    if _G.TheSim ~= nil and _G.TheSim.GetScreenPos ~= nil then
        local sx, sy = _G.TheSim:GetScreenPos(x, y, z)
        if sx ~= nil and sy ~= nil then
            return sx, sy, true
        end
    end
    return nil, nil, false
end

local function NormalizeAngle(angle)
    while angle <= -math.pi do
        angle = angle + TWO_PI
    end
    while angle > math.pi do
        angle = angle - TWO_PI
    end
    return angle
end

local function GetDirectionAngle(dx, dy)
    local angle = math.atan2(dy, dx)
    if angle < 0 then
        angle = angle + TWO_PI
    end
    return angle
end

local FlowerRayWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "FlowerRayWidget")

    self.owner = owner
    self.elapsed = 0
    self.labels = {}

    if self.SetHAnchor ~= nil then
        self:SetHAnchor(_G.ANCHOR_MIDDLE)
    end
    if self.SetVAnchor ~= nil then
        self:SetVAnchor(_G.ANCHOR_MIDDLE)
    end
    if self.SetScaleMode ~= nil then
        self:SetScaleMode(_G.SCALEMODE_PROPORTIONAL)
    end

    for i = 1, MAX_LABELS do
        local label = self:AddChild(Text(_G.CHATFONT, LABEL_FONT_SIZE, ""))
        label:Hide()
        self.labels[i] = label
    end

    self:StartUpdating()
end)

function FlowerRayWidget:HideAll()
    for i = 1, #self.labels do
        self.labels[i]:Hide()
    end
end

function FlowerRayWidget:GetTrackedPlayer()
    if self.owner ~= nil and self.owner:IsValid() then
        return self.owner
    end
    return _G.ThePlayer
end

function FlowerRayWidget:AppendMatches(raw_candidates, seen_guids, player, ents, screen_w, screen_h, psx, psy, has_player_screen)
    local px, py, pz = player.Transform:GetWorldPosition()

    for _, ent in ipairs(ents) do
        local target = ent ~= nil and ent:IsValid() and TARGET_PREFABS[ent.prefab] or nil
        if target == nil and ent ~= nil and ent:HasTag("player") then
            target = PLAYER_TARGET
        end
        if target ~= nil and not seen_guids[ent.GUID] then
            seen_guids[ent.GUID] = true
            local fx, fy, fz = ent.Transform:GetWorldPosition()
            local world_dx = fx - px
            local world_dz = fz - pz
            local dist_sq = world_dx * world_dx + world_dz * world_dz

            if dist_sq > 0.01 and dist_sq <= SEARCH_RADIUS * SEARCH_RADIUS then
                local dx, dy
                local has_screen_point = false
                local fsx, fsy, ok = GetScreenPoint(fx, fy, fz)
                if ok and has_player_screen then
                    dx = fsx - psx
                    dy = fsy - psy
                    has_screen_point = true
                end

                if not has_screen_point then
                    dx, dy = ApproximateScreenDelta(world_dx, world_dz)
                end

                local len_sq = dx * dx + dy * dy
                if len_sq > 1 then
                    raw_candidates[#raw_candidates + 1] = {
                        dx = dx,
                        dy = dy,
                        dist = math.sqrt(dist_sq),
                        angle = GetDirectionAngle(dx, dy),
                        screen_w = screen_w,
                        screen_h = screen_h,
                        player_sx = psx,
                        player_sy = psy,
                        has_player_screen = has_player_screen,
                        text = target.label,
                        color = target.color,
                    }
                end
            end
        end
    end
end

function FlowerRayWidget:CollectTargets(player)
    local px, py, pz = player.Transform:GetWorldPosition()
    local raw_candidates = {}
    local filtered_candidates = {}
    local seen_guids = {}
    local flower_ents = _G.TheSim:FindEntities(px, py, pz, SEARCH_RADIUS, FLOWER_MUST_TAGS, FLOWER_CANT_TAGS)
    local butterfly_ents = _G.TheSim:FindEntities(px, py, pz, SEARCH_RADIUS, BUTTERFLY_MUST_TAGS, BUTTERFLY_CANT_TAGS)
    local player_ents = _G.TheSim:FindEntities(px, py, pz, SEARCH_RADIUS, PLAYER_MUST_TAGS, PLAYER_CANT_TAGS)
    local touchstone_ents = _G.TheSim:FindEntities(px, py, pz, SEARCH_RADIUS, TOUCHSTONE_MUST_TAGS, TOUCHSTONE_CANT_TAGS)

    local psx, psy, has_player_screen = GetScreenPoint(px, py, pz)
    local screen_w, screen_h = 0, 0
    if _G.TheSim ~= nil and _G.TheSim.GetScreenSize ~= nil then
        screen_w, screen_h = _G.TheSim:GetScreenSize()
    end

    self:AppendMatches(raw_candidates, seen_guids, player, flower_ents, screen_w, screen_h, psx, psy, has_player_screen)
    self:AppendMatches(raw_candidates, seen_guids, player, butterfly_ents, screen_w, screen_h, psx, psy, has_player_screen)
    self:AppendMatches(raw_candidates, seen_guids, player, player_ents, screen_w, screen_h, psx, psy, has_player_screen)
    self:AppendMatches(raw_candidates, seen_guids, player, touchstone_ents, screen_w, screen_h, psx, psy, has_player_screen)

    table.sort(raw_candidates, function(a, b)
        if a.dist == b.dist then
            return a.text < b.text
        end
        return a.dist < b.dist
    end)

    for _, candidate in ipairs(raw_candidates) do
        local blocked = false
        for _, picked in ipairs(filtered_candidates) do
            if math.abs(NormalizeAngle(candidate.angle - picked.angle)) < MIN_ANGLE_SEPARATION then
                blocked = true
                break
            end
        end

        if not blocked then
            filtered_candidates[#filtered_candidates + 1] = candidate
            if #filtered_candidates >= MAX_LABELS then
                break
            end
        end
    end

    return filtered_candidates
end

function FlowerRayWidget:Refresh()
    local player = self:GetTrackedPlayer()
    if player == nil or player.Transform == nil or player.entity == nil then
        self:HideAll()
        return
    end

    local targets = self:CollectTargets(player)

    local moved_root = false
    for i = 1, MAX_LABELS do
        local data = targets[i]
        local label = self.labels[i]

        if data ~= nil then
            if data.has_player_screen then
                self:SetPosition(data.player_sx - data.screen_w * 0.5, data.player_sy - data.screen_h * 0.5 + PLAYER_SCREEN_Y_OFFSET, 0)
                moved_root = true
            end

            local len = math.sqrt(data.dx * data.dx + data.dy * data.dy)
            local ux = data.dx / len
            local uy = data.dy / len

            label:SetColour(data.color[1], data.color[2], data.color[3], data.color[4])
            label:SetString(string.format("%s %.0f", data.text, data.dist))
            label:SetPosition(ux * RING_RADIUS, uy * RING_RADIUS, 0)
            label:Show()
        else
            label:Hide()
        end
    end

    if not moved_root then
        self:SetPosition(0, PLAYER_SCREEN_Y_OFFSET, 0)
    end
end

function FlowerRayWidget:OnUpdate(dt)
    self.elapsed = self.elapsed + dt
    if self.elapsed < UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self:Refresh()
end

return FlowerRayWidget
