require("clientactionreach")
require("clientattackspeed")

local FlowerRayWidget = require("widgets/flowerraywidget")
local PlayerLatencyWidget = require("widgets/playerlatencywidget")

AddClassPostConstruct("screens/playerhud", function(self)
    if self ~= nil and self.flower_ray_widget == nil then
        self.flower_ray_widget = self:AddChild(FlowerRayWidget(self.owner))
    end
    if self ~= nil and self.player_latency_widget == nil then
        self.player_latency_widget = self:AddChild(PlayerLatencyWidget(self.owner))
    end
end)
