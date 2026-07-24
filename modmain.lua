require("clientactionreach")
require("clientattackspeed")

local FlowerRayWidget = require("widgets/flowerraywidget")
local GuideMenuWidget = require("widgets/guidemenuwidget")
local PlayerLatencyWidget = require("widgets/playerlatencywidget")
local Widget = require("widgets/widget")

AddClassPostConstruct("screens/playerhud", function(self)
    if self ~= nil and self.flower_ray_widget == nil then
        self.flower_ray_widget = self:AddChild(FlowerRayWidget(self.owner))
    end
    if self ~= nil and self.guide_menu_widget == nil then
        local parent = self.controls or self
        self.guide_menu_widget = parent:AddChild(GuideMenuWidget(self.owner))
    end
    if self ~= nil and self.player_latency_widget == nil then
        local parent = self.controls or self
        local root = parent:AddChild(Widget("rainyxin_latency_root"))
        if root.SetScaleMode ~= nil then
            root:SetScaleMode(GLOBAL.SCALEMODE_PROPORTIONAL)
        end
        if root.SetHAnchor ~= nil then
            root:SetHAnchor(GLOBAL.ANCHOR_LEFT)
        end
        if root.SetVAnchor ~= nil then
            root:SetVAnchor(GLOBAL.ANCHOR_TOP)
        end
        if root.SetMaxPropUpscale ~= nil and GLOBAL.MAX_HUD_SCALE ~= nil then
            root:SetMaxPropUpscale(GLOBAL.MAX_HUD_SCALE)
        end
        self.player_latency_root = root
        self.player_latency_widget = root:AddChild(PlayerLatencyWidget(self.owner, self.controls))
    end
    if self ~= nil and not self._rainyxin_guide_menu_keyhook then
        self._rainyxin_guide_menu_keyhook = true
        local old_OnRawKey = self.OnRawKey
        function self:OnRawKey(key, down)
            if old_OnRawKey ~= nil and old_OnRawKey(self, key, down) then
                return true
            end
            if down and key == GLOBAL.KEY_INSERT and self.guide_menu_widget ~= nil then
                self.guide_menu_widget:ToggleVisible()
                return true
            end
            return false
        end
    end
end)
