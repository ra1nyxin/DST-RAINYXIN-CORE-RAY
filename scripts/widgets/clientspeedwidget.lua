local _G = _G
local Class = _G.Class
local Widget = require("widgets/widget")

local UPDATE_INTERVAL = 0.25
local SPEED_SOURCE = "dst_rainyxin_core_ray_client_speed"
local SPEED_MULT = 1.05

local ClientSpeedWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "ClientSpeedWidget")

    self.owner = owner
    self.elapsed = 0
    self.applied_player = nil

    self:StartUpdating()
end)

function ClientSpeedWidget:GetTrackedPlayer()
    if self.owner ~= nil and self.owner:IsValid() then
        return self.owner
    end
    return _G.ThePlayer
end

function ClientSpeedWidget:RemovePredictedSpeed(player)
    if player ~= nil and player:IsValid() and player.components ~= nil then
        local playerspeedmult = player.components.playerspeedmult
        if playerspeedmult ~= nil and playerspeedmult.RemovePredictedSpeedMult ~= nil then
            playerspeedmult:RemovePredictedSpeedMult(SPEED_SOURCE)
        end
    end
end

function ClientSpeedWidget:ApplyPredictedSpeed(player)
    if player ~= nil and player:IsValid() and player.components ~= nil then
        local playerspeedmult = player.components.playerspeedmult
        if playerspeedmult ~= nil and playerspeedmult.SetPredictedSpeedMult ~= nil then
            playerspeedmult:SetPredictedSpeedMult(SPEED_SOURCE, SPEED_MULT)
            return true
        end
    end
    return false
end

function ClientSpeedWidget:Refresh()
    local player = self:GetTrackedPlayer()
    if player ~= self.applied_player then
        self:RemovePredictedSpeed(self.applied_player)
        self.applied_player = nil
    end

    if player == nil or not player:IsValid() then
        return
    end

    if self:ApplyPredictedSpeed(player) then
        self.applied_player = player
    end
end

function ClientSpeedWidget:OnUpdate(dt)
    self.elapsed = self.elapsed + dt
    if self.elapsed < UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self:Refresh()
end

return ClientSpeedWidget
