local _G = _G

local ACTIONS = _G.ACTIONS
if ACTIONS == nil then
    return
end

local EXTRA_PICKUP_REACH = 0.9
local EXTRA_PICK_REACH = 0.9
local EXTRA_HARVEST_REACH = 0.9
local EXTRA_MINE_REACH = 0.9
local EXTRA_DIG_REACH = 0.9
local EXTRA_CHOP_DISTANCE = 0.6

local function SafeCall(fn, ...)
    if fn == nil then
        return 0
    end

    local ok, result = pcall(fn, ...)
    if ok and type(result) == "number" then
        return result
    end

    return 0
end

local function AddExtraArriveDist(action, extra)
    if action == nil or type(extra) ~= "number" then
        return
    end
    if action._rainyxin_client_reach_extra_patched then
        return
    end

    local old_extra = action.extra_arrive_dist
    action.extra_arrive_dist = function(doer, dest, bufferedaction, arrive_dist)
        return SafeCall(old_extra, doer, dest, bufferedaction, arrive_dist) + extra
    end
    action._rainyxin_client_reach_extra_patched = true
end

local function AddDistance(action, extra)
    if action == nil or type(extra) ~= "number" then
        return
    end
    if action._rainyxin_client_reach_distance_patched then
        return
    end

    action.distance = (action.distance or 0) + extra
    action._rainyxin_client_reach_distance_patched = true
end

AddExtraArriveDist(ACTIONS.PICKUP, EXTRA_PICKUP_REACH)
AddExtraArriveDist(ACTIONS.PICK, EXTRA_PICK_REACH)
AddExtraArriveDist(ACTIONS.HARVEST, EXTRA_HARVEST_REACH)
AddExtraArriveDist(ACTIONS.MINE, EXTRA_MINE_REACH)
AddExtraArriveDist(ACTIONS.DIG, EXTRA_DIG_REACH)
AddDistance(ACTIONS.CHOP, EXTRA_CHOP_DISTANCE)
