local _G = _G
local Class = _G.Class
local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
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

local GuideMenuWidget = Class(Widget, function(self, owner)
    Widget._ctor(self, "GuideMenuWidget")

    self.owner = owner
    self.rows = {}
    self.scroll_offset = 0
    self.hovered = false
    self.hovered_row_index = nil
    self.pressed_row_index = nil
    self.dragging = false
    self.drag_anchor_mouse_x = 0
    self.drag_anchor_mouse_y = 0
    self.drag_anchor_menu_x = 0
    self.drag_anchor_menu_y = 0
    self.mouse_move_handler = nil
    self.mouse_button_handler = nil
    self.control_handler = nil

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
        local y = self.list_top_y - (i - 1) * ROW_HEIGHT
        local row = self:AddChild(Widget("guide_row_" .. i))
        row:SetPosition(0, y, 0)
        row.local_y = y
        row.base_tint = i % 2 == 1 and ROW_TINT_ODD or ROW_TINT_EVEN

        row.bg = CreatePanelRect(row, LIST_WIDTH, ROW_HEIGHT - 2, row.base_tint)
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

function GuideMenuWidget:GetWorldXY()
    local world_pos = self:GetWorldPosition()
    return world_pos ~= nil and world_pos.x or 0, world_pos ~= nil and world_pos.y or 0
end

function GuideMenuWidget:GetLocalMouse(mx, my)
    local world_x, world_y = self:GetWorldXY()
    return mx - world_x, my - world_y
end

function GuideMenuWidget:IsMouseInside(mx, my)
    if not GuideConfig.menu_visible then
        return false
    end
    if mx == nil or my == nil then
        return false
    end

    local world_x, world_y = self:GetWorldXY()
    return mx >= world_x - PANEL_WIDTH * 0.5
        and mx <= world_x + PANEL_WIDTH * 0.5
        and my >= world_y - PANEL_HEIGHT * 0.5
        and my <= world_y + PANEL_HEIGHT * 0.5
end

function GuideMenuWidget:IsPointInRect(local_x, local_y, center_x, center_y, width, height)
    return local_x >= center_x - width * 0.5
        and local_x <= center_x + width * 0.5
        and local_y >= center_y - height * 0.5
        and local_y <= center_y + height * 0.5
end

function GuideMenuWidget:GetRowIndexAtMouse(mx, my)
    if not self:IsMouseInside(mx, my) then
        return nil
    end

    local local_x, local_y = self:GetLocalMouse(mx, my)
    for i = 1, VISIBLE_ROWS do
        local row = self.rows[i]
        if row ~= nil and row.shown and self:IsPointInRect(local_x, local_y, 0, row.local_y, LIST_WIDTH, ROW_HEIGHT) then
            return i
        end
    end
    return nil
end

function GuideMenuWidget:IsMouseInTitle(mx, my)
    if not self:IsMouseInside(mx, my) then
        return false
    end

    local local_x, local_y = self:GetLocalMouse(mx, my)
    return self:IsPointInRect(local_x, local_y, 0, self.title_y, PANEL_WIDTH, TITLE_HEIGHT)
end

function GuideMenuWidget:UpdateRowHighlights()
    for i = 1, VISIBLE_ROWS do
        local row = self.rows[i]
        if row ~= nil then
            local tint = self.hovered_row_index == i and ROW_TINT_FOCUS or row.base_tint
            row.bg:SetTint(tint[1], tint[2], tint[3], tint[4])
        end
    end
end

function GuideMenuWidget:InstallInputHandlers()
    if self.mouse_move_handler == nil then
        self.mouse_move_handler = _G.TheInput:AddMoveHandler(function(mx, my)
            self.hovered = self:IsMouseInside(mx, my)
            self.hovered_row_index = self:GetRowIndexAtMouse(mx, my)
            self:UpdateRowHighlights()
            if self.dragging then
                local next_x = self.drag_anchor_menu_x + (mx - self.drag_anchor_mouse_x)
                local next_y = self.drag_anchor_menu_y + (my - self.drag_anchor_mouse_y)
                self:SetPosition(next_x, next_y, 0)
                GuideConfig:SetMenuPosition(next_x, next_y)
            end
        end)
    end

    if self.mouse_button_handler == nil then
        self.mouse_button_handler = _G.TheInput:AddMouseButtonHandler(function(button, is_up, x, y)
            if button ~= _G.MOUSEBUTTON_LEFT or not GuideConfig.menu_visible then
                return
            end

            x = x or _G.TheFrontEnd.lastx or 0
            y = y or _G.TheFrontEnd.lasty or 0

            -- DST's native callback names this boolean "is_up": false is press and true is release.
            if not is_up then
                if self:IsMouseInTitle(x, y) then
                    self:BeginDrag(x, y)
                    return
                end
                self.pressed_row_index = self:GetRowIndexAtMouse(x, y)
            else
                if self.dragging then
                    self:EndDrag()
                    return
                end

                local released_row_index = self:GetRowIndexAtMouse(x, y)
                if self.pressed_row_index ~= nil and self.pressed_row_index == released_row_index then
                    self:ToggleVisibleRow(released_row_index)
                end
                self.pressed_row_index = nil
            end
        end)
    end

    if self.control_handler == nil then
        self.control_handler = _G.TheInput:AddGeneralControlHandler(function(control, down)
            if not down or not self.hovered or not GuideConfig.menu_visible then
                return
            end

            if control == _G.CONTROL_SCROLLBACK then
                if self:ScrollBy(-SCROLL_STEP) then
                    return true
                end
            elseif control == _G.CONTROL_SCROLLFWD then
                if self:ScrollBy(SCROLL_STEP) then
                    return true
                end
            end
        end)
    end
end

function GuideMenuWidget:BeginDrag(mx, my)
    if self.dragging then
        return
    end

    self.dragging = true
    self.hovered = true
    self.pressed_row_index = nil
    self.drag_anchor_mouse_x = mx or _G.TheFrontEnd.lastx or 0
    self.drag_anchor_mouse_y = my or _G.TheFrontEnd.lasty or 0

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
    self.pressed_row_index = nil
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

    self:UpdateRowHighlights()

    local first_index, last_index = self:GetVisibleRange()
    self.footer:SetString(string.format("列表 %d-%d / %d", first_index, last_index, #GuideConfig.target_rows))
end

function GuideMenuWidget:SetMenuVisible(visible)
    GuideConfig:SetMenuVisible(visible)
    if visible then
        self:Show()
        self:MoveToFront()
        self.hovered = false
        self.hovered_row_index = nil
        self.pressed_row_index = nil
        self:RefreshRows()
    else
        self:EndDrag()
        self.hovered = false
        self.hovered_row_index = nil
        self.pressed_row_index = nil
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
    if self.mouse_button_handler ~= nil then
        self.mouse_button_handler:Remove()
        self.mouse_button_handler = nil
    end
    if self.control_handler ~= nil then
        self.control_handler:Remove()
        self.control_handler = nil
    end
end

return GuideMenuWidget
