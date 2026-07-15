require("clientactionreach")
require("clientattackspeed")

local FlowerRayWidget = require("widgets/flowerraywidget")
local ClientSpeedWidget = require("widgets/clientspeedwidget")

AddClassPostConstruct("screens/playerhud", function(self)
    if self ~= nil and self.flower_ray_widget == nil then
        self.flower_ray_widget = self:AddChild(FlowerRayWidget(self.owner))
    end
    if self ~= nil and self.client_speed_widget == nil then
        self.client_speed_widget = self:AddChild(ClientSpeedWidget(self.owner))
    end
end)
