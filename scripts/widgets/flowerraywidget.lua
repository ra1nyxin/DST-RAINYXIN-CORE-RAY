local _G = _G
local Class = _G.Class
local Widget = require("widgets/widget")
local Text = require("widgets/text")

local UPDATE_INTERVAL = 0.1
local TOPOLOGY_SCAN_INTERVAL = 2
local SEARCH_RADIUS = 100
local PIGKING_ENTITY_RADIUS = 160
local RING_RADIUS = 104
local PLAYER_SCREEN_Y_OFFSET = 28
local LABEL_FONT_SIZE = 19
local BUTTERFLY_MUST_TAGS = { "butterfly" }
local BUTTERFLY_CANT_TAGS = { "INLIMBO", "NOCLICK", "FX", "DECOR" }
local PLAYER_MUST_TAGS = { "player" }
local PLAYER_CANT_TAGS = { "INLIMBO", "playerghost", "FX", "DECOR" }
local TOUCHSTONE_MUST_TAGS = { "resurrector" }
local TOUCHSTONE_CANT_TAGS = { "INLIMBO", "NOCLICK", "FX", "DECOR" }
local PIGKING_MUST_TAGS = { "king" }
local PIGKING_CANT_TAGS = { "INLIMBO", "NOCLICK", "FX", "DECOR" }
local PIGKING_NODE_PREFIXES = { "PigKingdom", "PigCity" }
local PLAYER_TARGET = { label = "人", color = { 1, 1, 1, 0.95 } }
local TARGET_PREFABS = {
    butterfly = { label = "蝶", color = { 1, 0.9, 0.45, 0.95 } },
    pigking = { label = "猪王", color = { 1, 0.72, 0.22, 0.98 } },
    resurrectionstone = { label = "试金石", color = { 0.7, 0.95, 1, 0.95 } },
}

local DEGREES = _G.DEGREES or (math.pi / 180)

local function ApproximateScreenDelta(dx, dz)
    if _G.TheCamera ~= nil and _G.TheCamera.GetRightVec ~= nil and _G.TheCamera.GetDownVec ~= nil then
        local right = _G.TheCamera:GetRightVec()
        local down = _G.TheCamera:GetDownVec()
        if right ~= nil and down ~= nil then
            local sx = dx * right.x + dz * right.z
            local sy = -(dx * down.x + dz * down.z)
            return sx, sy
        end
    end

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
    local rx = dx * cos_h - dz * sin_h
    local rz = dx * sin_h + dz * cos_h
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

local function ComputeNodeCenter(node)
    if node == nil then
        return nil, nil
    end

    local cent = node.cent
    if cent ~= nil and cent[1] ~= nil and cent[2] ~= nil then
        return cent[1], cent[2]
    end

    if node.x ~= nil and node.y ~= nil then
        return node.x, node.y
    end

    local poly = node.poly
    if poly == nil or #poly == 0 then
        return nil, nil
    end

    local sum_x = 0
    local sum_z = 0
    for i = 1, #poly do
        local point = poly[i]
        if point ~= nil and point[1] ~= nil and point[2] ~= nil then
            sum_x = sum_x + point[1]
            sum_z = sum_z + point[2]
        end
    end

    return sum_x / #poly, sum_z / #poly
end

local function HasNodeSuffix(node_id, suffix)
    return node_id == suffix or node_id:sub(-#suffix) == suffix
end

local FlowerRayWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "FlowerRayWidget")

    self.owner = owner
    self.elapsed = 0
    self.labels = {}
    self.cached_world = nil
    self.cached_pigking_targets = nil
    self.cached_pigking_world = nil
    self.cached_pigking_actual = nil
    self.cached_touchstones = {}
    self.next_topology_scan_time = 0

    if self.SetHAnchor ~= nil then
        self:SetHAnchor(_G.ANCHOR_MIDDLE)
    end
    if self.SetVAnchor ~= nil then
        self:SetVAnchor(_G.ANCHOR_MIDDLE)
    end
    if self.SetScaleMode ~= nil then
        self:SetScaleMode(_G.SCALEMODE_PROPORTIONAL)
    end

    self:StartUpdating()
end)

function FlowerRayWidget:HideAll()
    for i = 1, #self.labels do
        self.labels[i]:Hide()
    end
end

function FlowerRayWidget:EnsureLabelCount(count)
    while #self.labels < count do
        local label = self:AddChild(Text(_G.CHATFONT, LABEL_FONT_SIZE, ""))
        label:Hide()
        self.labels[#self.labels + 1] = label
    end
end

function FlowerRayWidget:GetTrackedPlayer()
    if self.owner ~= nil and self.owner:IsValid() then
        return self.owner
    end
    return _G.ThePlayer
end

function FlowerRayWidget:ResetWorldCaches()
    self.cached_world = _G.TheWorld
    self.cached_pigking_targets = nil
    self.cached_pigking_world = nil
    self.cached_pigking_actual = nil
    self.cached_touchstones = {}
    self.next_topology_scan_time = 0
end

function FlowerRayWidget:EnsureWorldCaches()
    local world = _G.TheWorld
    if self.cached_world ~= world then
        self:ResetWorldCaches()
    end
end

function FlowerRayWidget:CacheStaticTarget(cache, cache_id, world_x, world_z, target)
    if cache == nil or cache_id == nil or world_x == nil or world_z == nil or target == nil then
        return
    end

    cache[cache_id] = {
        x = world_x,
        z = world_z,
        target = target,
    }
end

function FlowerRayWidget:RefreshPigKingTopologyCache()
    local world = _G.TheWorld
    local topology = world ~= nil and world.topology or nil
    local targets = {}

    if topology ~= nil and topology.ids ~= nil and topology.nodes ~= nil then
        for index, node_id in ipairs(topology.ids) do
            if type(node_id) == "string" then
                for _, prefix in ipairs(PIGKING_NODE_PREFIXES) do
                    if HasNodeSuffix(node_id, prefix) then
                        local node = topology.nodes[index]
                        local x, z = ComputeNodeCenter(node)
                        if x ~= nil and z ~= nil then
                            targets[#targets + 1] = {
                                x = x,
                                z = z,
                                node_id = node_id,
                            }
                        end
                        break
                    end
                end
            end
        end
    end

    self.cached_pigking_targets = targets
    self.cached_pigking_world = world
end

function FlowerRayWidget:EnsurePigKingTopologyCache()
    local world = _G.TheWorld
    if self.cached_pigking_world ~= world then
        self:ResetWorldCaches()
    end

    local now = _G.GetTime ~= nil and _G.GetTime() or 0
    if self.cached_pigking_targets ~= nil and now < self.next_topology_scan_time then
        return
    end

    self.next_topology_scan_time = now + TOPOLOGY_SCAN_INTERVAL
    self:RefreshPigKingTopologyCache()
end

function FlowerRayWidget:GetBestPigKingTopologyTarget(player)
    self:EnsurePigKingTopologyCache()

    local targets = self.cached_pigking_targets
    if targets == nil or targets[1] == nil then
        return nil
    end

    local px, _, pz = player.Transform:GetWorldPosition()
    local best_target = nil
    local best_dist_sq = nil

    for i = 1, #targets do
        local target = targets[i]
        local dx = target.x - px
        local dz = target.z - pz
        local dist_sq = dx * dx + dz * dz
        if best_dist_sq == nil or dist_sq < best_dist_sq then
            best_target = target
            best_dist_sq = dist_sq
        end
    end

    return best_target
end

function FlowerRayWidget:AppendPointTarget(raw_candidates, player, world_x, world_z, screen_w, screen_h, psx, psy, has_player_screen, target, use_screen_projection)
    if world_x == nil or world_z == nil or target == nil then
        return
    end

    local px, py, pz = player.Transform:GetWorldPosition()
    local world_dx = world_x - px
    local world_dz = world_z - pz
    local dist_sq = world_dx * world_dx + world_dz * world_dz

    if dist_sq <= 0.01 then
        return
    end

    local dx, dy
    local has_screen_point = false
    if use_screen_projection then
        local fsx, fsy, ok = GetScreenPoint(world_x, py, world_z)
        if ok and has_player_screen then
            dx = fsx - psx
            dy = fsy - psy
            has_screen_point = true
        end
    end

    if not has_screen_point then
        dx, dy = ApproximateScreenDelta(world_dx, world_dz)
    end

    local len_sq = dx * dx + dy * dy
    if len_sq <= 1 then
        return
    end

    raw_candidates[#raw_candidates + 1] = {
        dx = dx,
        dy = dy,
        dist = math.sqrt(dist_sq),
        screen_w = screen_w,
        screen_h = screen_h,
        player_sx = psx,
        player_sy = psy,
        has_player_screen = has_player_screen,
        text = target.label,
        color = target.color,
    }
end

function FlowerRayWidget:AppendCachedTargets(raw_candidates, player, cache, screen_w, screen_h, psx, psy, has_player_screen)
    if cache == nil then
        return
    end

    for _, entry in pairs(cache) do
        if entry ~= nil then
            self:AppendPointTarget(raw_candidates, player, entry.x, entry.z, screen_w, screen_h, psx, psy, has_player_screen, entry.target, false)
        end
    end
end

function FlowerRayWidget:AppendMatches(raw_candidates, seen_guids, player, ents, screen_w, screen_h, psx, psy, has_player_screen, max_distance)
    local px, py, pz = player.Transform:GetWorldPosition()
    local max_dist = max_distance or SEARCH_RADIUS

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

            if dist_sq > 0.01 and dist_sq <= max_dist * max_dist then
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
    self:EnsureWorldCaches()

    local px, py, pz = player.Transform:GetWorldPosition()
    local raw_candidates = {}
    local seen_guids = {}
    local butterfly_ents = _G.TheSim:FindEntities(px, py, pz, SEARCH_RADIUS, BUTTERFLY_MUST_TAGS, BUTTERFLY_CANT_TAGS)
    local player_ents = _G.TheSim:FindEntities(px, py, pz, SEARCH_RADIUS, PLAYER_MUST_TAGS, PLAYER_CANT_TAGS)
    local touchstone_ents = _G.TheSim:FindEntities(px, py, pz, SEARCH_RADIUS, TOUCHSTONE_MUST_TAGS, TOUCHSTONE_CANT_TAGS)
    local king_ents = _G.TheSim:FindEntities(px, py, pz, PIGKING_ENTITY_RADIUS, PIGKING_MUST_TAGS, PIGKING_CANT_TAGS)

    local psx, psy, has_player_screen = GetScreenPoint(px, py, pz)
    local screen_w, screen_h = 0, 0
    if _G.TheSim ~= nil and _G.TheSim.GetScreenSize ~= nil then
        screen_w, screen_h = _G.TheSim:GetScreenSize()
    end

    self:AppendMatches(raw_candidates, seen_guids, player, butterfly_ents, screen_w, screen_h, psx, psy, has_player_screen)
    self:AppendMatches(raw_candidates, seen_guids, player, player_ents, screen_w, screen_h, psx, psy, has_player_screen)
    self:AppendMatches(raw_candidates, seen_guids, player, touchstone_ents, screen_w, screen_h, psx, psy, has_player_screen)

    for _, ent in ipairs(touchstone_ents) do
        if ent ~= nil and ent:IsValid() and ent.prefab == "resurrectionstone" then
            local tx, _, tz = ent.Transform:GetWorldPosition()
            self:CacheStaticTarget(self.cached_touchstones, tostring(ent.GUID), tx, tz, TARGET_PREFABS.resurrectionstone)
        end
    end
    local cached_touchstones = {}
    for cache_id, entry in pairs(self.cached_touchstones) do
        if not seen_guids[tonumber(cache_id)] then
            cached_touchstones[cache_id] = entry
        end
    end
    self:AppendCachedTargets(raw_candidates, player, cached_touchstones, screen_w, screen_h, psx, psy, has_player_screen)

    local has_real_pigking = false
    for _, ent in ipairs(king_ents) do
        if ent ~= nil and ent:IsValid() and ent.prefab == "pigking" then
            has_real_pigking = true
            local kx, _, kz = ent.Transform:GetWorldPosition()
            self.cached_pigking_actual = { x = kx, z = kz }
            self:AppendMatches(raw_candidates, seen_guids, player, { ent }, screen_w, screen_h, psx, psy, has_player_screen, PIGKING_ENTITY_RADIUS)
        end
    end

    if not has_real_pigking and self.cached_pigking_actual ~= nil then
        self:AppendPointTarget(raw_candidates, player, self.cached_pigking_actual.x, self.cached_pigking_actual.z, screen_w, screen_h, psx, psy, has_player_screen, TARGET_PREFABS.pigking, false)
    elseif not has_real_pigking then
        local pigking_target = self:GetBestPigKingTopologyTarget(player)
        if pigking_target ~= nil then
            self:AppendPointTarget(raw_candidates, player, pigking_target.x, pigking_target.z, screen_w, screen_h, psx, psy, has_player_screen, TARGET_PREFABS.pigking, false)
        end
    end

    table.sort(raw_candidates, function(a, b)
        if a.dist == b.dist then
            return a.text < b.text
        end
        return a.dist < b.dist
    end)

    return raw_candidates
end

function FlowerRayWidget:Refresh()
    local player = self:GetTrackedPlayer()
    if player == nil or player.Transform == nil or player.entity == nil then
        self:HideAll()
        return
    end

    local targets = self:CollectTargets(player)
    self:EnsureLabelCount(#targets)

    local moved_root = false
    for i = 1, #targets do
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
        end
    end

    for i = #targets + 1, #self.labels do
        self.labels[i]:Hide()
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
