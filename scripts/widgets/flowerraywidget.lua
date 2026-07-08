local _G = _G
local Class = _G.Class
local Widget = require("widgets/widget")
local Text = require("widgets/text")

local UPDATE_INTERVAL = 0.1
local SEARCH_RADIUS = 100
local RING_RADIUS = 92
local PLAYER_SCREEN_Y_OFFSET = 28
local MAX_ARROWS = 12
local MIN_ANGLE_SEPARATION = 12 * (_G.DEGREES or (math.pi / 180))
local ARROW_FONT_SIZE = 20
local FLOWER_PREFABS = {
    flower = true,
    flower_evil = true,
    flower_rose = true,
}
local FLOWER_MUST_TAGS = { "pickable" }
local FLOWER_CANT_TAGS = { "INLIMBO", "NOCLICK", "FX", "DECOR" }
local ARROW_CHAR = "\226\150\178"

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
    self.arrows = {}

    if self.SetHAnchor ~= nil then
        self:SetHAnchor(_G.ANCHOR_MIDDLE)
    end
    if self.SetVAnchor ~= nil then
        self:SetVAnchor(_G.ANCHOR_MIDDLE)
    end
    if self.SetScaleMode ~= nil then
        self:SetScaleMode(_G.SCALEMODE_PROPORTIONAL)
    end

    for i = 1, MAX_ARROWS do
        local arrow = self:AddChild(Text(_G.CHATFONT, ARROW_FONT_SIZE, ""))
        arrow:SetColour(1, 0.95, 0.3, 0.95)
        arrow:Hide()
        self.arrows[i] = arrow
    end

    self:StartUpdating()
end)

function FlowerRayWidget:HideAll()
    for i = 1, #self.arrows do
        self.arrows[i]:Hide()
    end
end

function FlowerRayWidget:GetTrackedPlayer()
    if self.owner ~= nil and self.owner:IsValid() then
        return self.owner
    end
    return _G.ThePlayer
end

function FlowerRayWidget:CollectFlowers(player)
    local px, py, pz = player.Transform:GetWorldPosition()
    local raw_candidates = {}
    local filtered_candidates = {}
    local ents = _G.TheSim:FindEntities(px, py, pz, SEARCH_RADIUS, FLOWER_MUST_TAGS, FLOWER_CANT_TAGS)

    local psx, psy, has_player_screen = GetScreenPoint(px, py, pz)
    local screen_w, screen_h = 0, 0
    if _G.TheSim ~= nil and _G.TheSim.GetScreenSize ~= nil then
        screen_w, screen_h = _G.TheSim:GetScreenSize()
    end

    for _, ent in ipairs(ents) do
        if ent ~= nil and ent:IsValid() and FLOWER_PREFABS[ent.prefab] then
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
                    local dist = math.sqrt(dist_sq)
                    raw_candidates[#raw_candidates + 1] = {
                        dx = dx,
                        dy = dy,
                        dist = dist,
                        angle = GetDirectionAngle(dx, dy),
                        screen_w = screen_w,
                        screen_h = screen_h,
                        player_sx = psx,
                        player_sy = psy,
                        has_player_screen = has_player_screen,
                    }
                end
            end
        end
    end

    table.sort(raw_candidates, function(a, b)
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
            if #filtered_candidates >= MAX_ARROWS then
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

    local flowers = self:CollectFlowers(player)

    local moved_root = false
    for i = 1, MAX_ARROWS do
        local data = flowers[i]
        local arrow = self.arrows[i]

        if data ~= nil then
            if data.has_player_screen then
                self:SetPosition(data.player_sx - data.screen_w * 0.5, data.player_sy - data.screen_h * 0.5 + PLAYER_SCREEN_Y_OFFSET, 0)
                moved_root = true
            end

            local len = math.sqrt(data.dx * data.dx + data.dy * data.dy)
            local ux = data.dx / len
            local uy = data.dy / len

            arrow:SetString(string.format("%s %.0f", ARROW_CHAR, data.dist))
            arrow:SetPosition(ux * RING_RADIUS, uy * RING_RADIUS, 0)
            arrow:Show()
        else
            arrow:Hide()
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
