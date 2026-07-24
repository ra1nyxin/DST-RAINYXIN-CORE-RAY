local _G = _G
local Class = _G.Class
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local ImageButton = require("widgets/imagebutton")
local GuideConfig = require("guideconfig")

local PANEL_WIDTH = 360
local PANEL_PADDING = 12
local TITLE_HEIGHT = 34
local HINT_HEIGHT = 24
local BODY_FONT_SIZE = 18
local TITLE_FONT_SIZE = 24
local ROW_HEIGHT = 28
local VISIBLE_ROWS = 10
local LIST_GAP_TOP = 12
local INFO_GAP_TOP = 8
local FOOTER_HEIGHT = 44
local PANEL_HEIGHT = PANEL_PADDING
    + TITLE_HEIGHT
    + 8
    + HINT_HEIGHT
    + LIST_GAP_TOP
    + VISIBLE_ROWS * ROW_HEIGHT
    + INFO_GAP_TOP
    + FOOTER_HEIGHT
    + PANEL_PADDING
local LIST_WIDTH = PANEL_WIDTH - PANEL_PADDING * 2
local SCROLL_STEP = 1

local BG_TINT = { 0.06, 0.07, 0.08, 0.90 }
local TITLE_TINT = { 0.16, 0.13, 0.09, 0.97 }
local ROW_TINT_ODD = { 0.16, 0.16, 0.16, 0.90 }
local ROW_TINT_EVEN = { 0.12, 0.12, 0.12, 0.90 }
local ROW_TINT_FOCUS = { 0.26, 0.22, 0.12, 0.97 }
local TITLE_COLOR = { 1.00, 0.92, 0.55, 0.98 }
local HINT_COLOR = { 0.78, 0.88, 1.00, 0.92 }
local ENABLED_COLOR = { 1.00, 1.00, 1.00, 0.97 }
local DISABLED_COLOR = { 0.62, 0.62, 0.62, 0.86 }
local FOOTER_COLOR = { 0.78, 0.95, 0.82, 0.92 }

local function Clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    end
    if value > max_value then
        return max_value
    end
    return value
end

local function CreatePanelRect(parent, width, height, tint)
    local image = parent:AddChild(Image("images/global.xml", "square.tex"))
    image:SetSize(width, height)
    image:SetTint(tint[1], tint[2], tint[3], tint[4])
    image:SetClickable(false)
    return image
end

local function CreateAlignedText(parent, width, size, color)
    local text = parent:AddChild(Text(_G.CHATFONT, size, ""))
    text:SetRegionSize(width, ROW_HEIGHT)
    text:SetHAlign(_G.ANCHOR_LEFT)
    text:SetColour(color[1], color[2], color[3], color[4])
    text:SetClickable(false)
    return text
end

local function CreateHitButton(parent, width, height, onclick)
    local button = parent:AddChild(ImageButton("images/ui.xml", "blank.tex", "blank.tex", "blank.tex", "blank.tex", "blank.tex"))
    button:ForceImageSize(width, height)
    -- The Button root has no visual bounds. Only its scaled Image child may take mouse hits.
    button:SetClickable(false)
    button.scale_on_focus = false
    button.move_on_click = false
    button.ignore_standard_scaling = true
    button:SetNormalScale(1, 1, 1)
    button:SetFocusScale(1, 1, 1)

    -- The blank texture stays visually empty, but must retain alpha for mouse ray hits.
    button:SetImageNormalColour(1, 1, 1, 1)
    button:SetImageFocusColour(1, 1, 1, 1)
    button:SetImageDisabledColour(1, 1, 1, 1)
    button:SetImageSelectedColour(1, 1, 1, 1)
    button.image:SetClickable(true)
    button.image.focus_forward = button
    button:SetOnClick(onclick)
    return button
end

local function AddScrollHandler(button, menu)
    local old_on_control = button.OnControl
    function button:OnControl(control, down)
        if down and GuideConfig.menu_visible then
            if control == _G.CONTROL_SCROLLBACK and menu:ScrollBy(-SCROLL_STEP) then
                return true
            elseif control == _G.CONTROL_SCROLLFWD and menu:ScrollBy(SCROLL_STEP) then
                return true
            end
        end
        return old_on_control(self, control, down)
    end
end

local GuideMenuWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "GuideMenuWidget")

    self.owner = owner
    self.rows = {}
    self.scroll_offset = 0
    self.hovered = false
    self.dragging = false
    self.drag_anchor_mouse_x = 0
    self.drag_anchor_mouse_y = 0
    self.drag_anchor_menu_x = 0
    self.drag_anchor_menu_y = 0
    self.mouse_move_handler = nil

    if self.SetScaleMode ~= nil then
        self:SetScaleMode(_G.SCALEMODE_PROPORTIONAL)
    end
    if self.SetHAnchor ~= nil then
        self:SetHAnchor(_G.ANCHOR_MIDDLE)
    end
    if self.SetVAnchor ~= nil then
        self:SetVAnchor(_G.ANCHOR_MIDDLE)
    end
    if self.SetMaxPropUpscale ~= nil and _G.MAX_HUD_SCALE ~= nil then
        self:SetMaxPropUpscale(_G.MAX_HUD_SCALE)
    end

    self:SetPosition(GuideConfig.menu_position.x, GuideConfig.menu_position.y, 0)

    self.bg = CreatePanelRect(self, PANEL_WIDTH, PANEL_HEIGHT, BG_TINT)
    self.title_bg = CreatePanelRect(self, PANEL_WIDTH, TITLE_HEIGHT, TITLE_TINT)
    local top_y = PANEL_HEIGHT * 0.5
    self.title_y = top_y - PANEL_PADDING - TITLE_HEIGHT * 0.5
    self.title_bg:SetPosition(0, self.title_y, 0)

    self.title = self:AddChild(Text(_G.CHATFONT, TITLE_FONT_SIZE, "RAY 指引菜单"))
    self.title:SetColour(TITLE_COLOR[1], TITLE_COLOR[2], TITLE_COLOR[3], TITLE_COLOR[4])
    self.title:SetPosition(0, self.title_y, 0)
    self.title:SetClickable(false)

    self.title_button = CreateHitButton(self, PANEL_WIDTH, TITLE_HEIGHT, function()
        self:EndDrag()
    end)
    self.title_button:SetPosition(0, self.title_y, 0)
    self.title_button:SetOnDown(function()
        self:BeginDrag()
    end)
    AddScrollHandler(self.title_button, self)

    self.hint = self:AddChild(Text(_G.CHATFONT, BODY_FONT_SIZE, "[Insert] 显隐  |  左键拖动标题  |  滚轮翻页"))
    self.hint:SetColour(HINT_COLOR[1], HINT_COLOR[2], HINT_COLOR[3], HINT_COLOR[4])
    self.hint:SetPosition(0, self.title_y - TITLE_HEIGHT * 0.5 - 8 - HINT_HEIGHT * 0.5, 0)
    self.hint:SetClickable(false)

    self.footer = self:AddChild(Text(_G.CHATFONT, BODY_FONT_SIZE, ""))
    self.footer:SetColour(FOOTER_COLOR[1], FOOTER_COLOR[2], FOOTER_COLOR[3], FOOTER_COLOR[4])
    self.footer:SetPosition(0, -PANEL_HEIGHT * 0.5 + PANEL_PADDING + 10, 0)
    self.footer:SetClickable(false)

    self.info = self:AddChild(Text(_G.CHATFONT, BODY_FONT_SIZE, "远处地标优先走拓扑/布局中心；试金石发现后会缓存。"))
    self.info:SetColour(FOOTER_COLOR[1], FOOTER_COLOR[2], FOOTER_COLOR[3], FOOTER_COLOR[4])
    self.info:SetPosition(0, -PANEL_HEIGHT * 0.5 + PANEL_PADDING + 30, 0)
    self.info:SetClickable(false)

    self.list_top_y = self.title_y - TITLE_HEIGHT * 0.5 - 8 - HINT_HEIGHT - LIST_GAP_TOP - ROW_HEIGHT * 0.5
    for i = 1, VISIBLE_ROWS do
        local visible_index = i
        local y = self.list_top_y - (visible_index - 1) * ROW_HEIGHT
        local row = self:AddChild(Widget("guide_row_" .. i))
        row:SetPosition(0, y, 0)
        row.local_y = y
        row.base_tint = visible_index % 2 == 1 and ROW_TINT_ODD or ROW_TINT_EVEN

        row.bg = CreatePanelRect(row, LIST_WIDTH, ROW_HEIGHT - 2, row.base_tint)
        row.button = CreateHitButton(row, LIST_WIDTH, ROW_HEIGHT, function()
            self:ToggleVisibleRow(visible_index)
        end)
        row.button:SetOnGainFocus(function()
            row.bg:SetTint(ROW_TINT_FOCUS[1], ROW_TINT_FOCUS[2], ROW_TINT_FOCUS[3], ROW_TINT_FOCUS[4])
        end)
        row.button:SetOnLoseFocus(function()
            row.bg:SetTint(row.base_tint[1], row.base_tint[2], row.base_tint[3], row.base_tint[4])
        end)
        AddScrollHandler(row.button, self)
        row.text = CreateAlignedText(row, LIST_WIDTH - 18, BODY_FONT_SIZE, ENABLED_COLOR)
        row.text:SetPosition(8, 0, 0)
        self.rows[i] = row
    end

    self:InstallInputHandlers()
    self:RefreshRows()
    self:SetMenuVisible(GuideConfig.menu_visible)
end)

function GuideMenuWidget:GetMaxScrollOffset()
    return math.max(0, #GuideConfig.target_rows - VISIBLE_ROWS)
end

function GuideMenuWidget:GetVisibleRange()
    local first_index = self.scroll_offset + 1
    local last_index = math.min(#GuideConfig.target_rows, self.scroll_offset + VISIBLE_ROWS)
    return first_index, last_index
end

function GuideMenuWidget:InstallInputHandlers()
    if self.mouse_move_handler == nil then
        self.mouse_move_handler = _G.TheInput:AddMoveHandler(function(mx, my)
            if self.dragging then
                local next_x = self.drag_anchor_menu_x + (mx - self.drag_anchor_mouse_x)
                local next_y = self.drag_anchor_menu_y + (my - self.drag_anchor_mouse_y)
                self:SetPosition(next_x, next_y, 0)
                GuideConfig:SetMenuPosition(next_x, next_y)
            end
        end)
    end

end

function GuideMenuWidget:BeginDrag()
    if self.dragging then
        return
    end

    self.dragging = true
    self.hovered = true
    local mouse_pos = _G.TheInput:GetScreenPosition()
    self.drag_anchor_mouse_x = mouse_pos ~= nil and mouse_pos.x or 0
    self.drag_anchor_mouse_y = mouse_pos ~= nil and mouse_pos.y or 0

    local pos = self:GetPosition()
    self.drag_anchor_menu_x = pos.x
    self.drag_anchor_menu_y = pos.y

    if _G.TheFrontEnd ~= nil then
        _G.TheFrontEnd:LockFocus(true)
    end
    self:MoveToFront()
end

function GuideMenuWidget:EndDrag()
    if not self.dragging then
        return
    end

    self.dragging = false
    if _G.TheFrontEnd ~= nil then
        _G.TheFrontEnd:LockFocus(false)
    end
end

function GuideMenuWidget:ScrollBy(delta)
    local next_offset = Clamp(self.scroll_offset + delta, 0, self:GetMaxScrollOffset())
    if next_offset == self.scroll_offset then
        return false
    end
    self.scroll_offset = next_offset
    self:RefreshRows()
    return true
end

function GuideMenuWidget:ToggleVisibleRow(visible_index)
    local data_index = self.scroll_offset + visible_index
    local row_def = GuideConfig.target_rows[data_index]
    if row_def == nil then
        return
    end

    GuideConfig:ToggleEnabled(row_def.key)
    self:RefreshRows()
end

function GuideMenuWidget:RefreshRows()
    for i = 1, VISIBLE_ROWS do
        local row = self.rows[i]
        local data_index = self.scroll_offset + i
        local row_def = GuideConfig.target_rows[data_index]

        if row_def ~= nil then
            local enabled = GuideConfig:IsEnabled(row_def.key)
            row.text:SetString(string.format("[%s] %s", enabled and "x" or " ", row_def.label))
            local color = enabled and ENABLED_COLOR or DISABLED_COLOR
            row.text:SetColour(color[1], color[2], color[3], color[4])
            row:Show()
        else
            row:Hide()
        end
    end

    local first_index, last_index = self:GetVisibleRange()
    self.footer:SetString(string.format("列表 %d-%d / %d", first_index, last_index, #GuideConfig.target_rows))
end

function GuideMenuWidget:SetMenuVisible(visible)
    GuideConfig:SetMenuVisible(visible)
    if visible then
        self:Show()
        self:MoveToFront()
        self.hovered = false
        self:RefreshRows()
    else
        self:EndDrag()
        self.hovered = false
        self:Hide()
    end
end

function GuideMenuWidget:ToggleVisible()
    self:SetMenuVisible(not GuideConfig.menu_visible)
end

function GuideMenuWidget:OnRemoveEntity()
    self:EndDrag()
    if self.mouse_move_handler ~= nil then
        self.mouse_move_handler:Remove()
        self.mouse_move_handler = nil
    end
end

return GuideMenuWidget
