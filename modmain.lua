local FlowerRayWidget = require("widgets/flowerraywidget")

AddClassPostConstruct("screens/playerhud", function(self)
    if self ~= nil and self.flower_ray_widget == nil then
        self.flower_ray_widget = self:AddChild(FlowerRayWidget(self.owner))
    end
end)
