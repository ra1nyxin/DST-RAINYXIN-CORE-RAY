local _G = _G
local AddStategraphPostInit = _G.AddStategraphPostInit

local ATTACK_PERIOD_MULT = 0.85
local ATTACK_TIMEOUT_MULT = 0.85
local ATTACK_BUTTON_REPEAT_COOLDOWN = 0.15

local function IsLocalPlayer(inst)
    return inst ~= nil and inst == _G.ThePlayer
end

local CombatReplica = require("components/combat_replica")
if CombatReplica ~= nil and not CombatReplica._rainyxin_attack_speed_patched then
    CombatReplica._rainyxin_attack_speed_patched = true

    local old_MinAttackPeriod = CombatReplica.MinAttackPeriod
    function CombatReplica:MinAttackPeriod(...)
        local period = old_MinAttackPeriod(self, ...)
        if IsLocalPlayer(self.inst) and type(period) == "number" and period > 0 then
            return period * ATTACK_PERIOD_MULT
        end
        return period
    end

    local old_InCooldown = CombatReplica.InCooldown
    function CombatReplica:InCooldown(...)
        if IsLocalPlayer(self.inst) and self.inst.components.combat == nil and self.classified ~= nil then
            local period = self.classified.minattackperiod:value()
            if type(period) == "number" and period > 0 and self._laststartattacktime ~= nil then
                return self._laststartattacktime + period * ATTACK_PERIOD_MULT > _G.GetTime()
            end
        end
        return old_InCooldown(self, ...)
    end
end

local PlayerController = require("components/playercontroller")
if PlayerController ~= nil and not PlayerController._rainyxin_attack_speed_patched then
    PlayerController._rainyxin_attack_speed_patched = true

    local old_RemoteAttackButton = PlayerController.RemoteAttackButton
    function PlayerController:RemoteAttackButton(target, force_attack, isleftmouse, isreleased)
        if IsLocalPlayer(self.inst) then
            self.remote_controls[isleftmouse and _G.CONTROL_PRIMARY or _G.CONTROL_ATTACK] =
                not isreleased and (target and ATTACK_BUTTON_REPEAT_COOLDOWN or 0) or nil

            if self.locomotor ~= nil then
                _G.SendRPCToServer(_G.RPC.AttackButton, target, force_attack, nil, isleftmouse, isreleased)
            elseif target ~= nil then
                _G.SendRPCToServer(_G.RPC.AttackButton, target, force_attack, true, isleftmouse, isreleased)
            else
                _G.SendRPCToServer(_G.RPC.AttackButton, nil, nil, nil, isleftmouse, isreleased)
            end
            return
        end

        return old_RemoteAttackButton(self, target, force_attack, isleftmouse, isreleased)
    end
end

local function PatchAttackState(sg)
    local attack_state = sg ~= nil and sg.states ~= nil and sg.states.attack or nil
    if attack_state == nil or attack_state._rainyxin_attack_speed_patched then
        return
    end

    attack_state._rainyxin_attack_speed_patched = true

    local old_onenter = attack_state.onenter
    attack_state.onenter = function(inst, ...)
        if old_onenter ~= nil then
            old_onenter(inst, ...)
        end

        if IsLocalPlayer(inst) and inst.sg ~= nil and inst.sg.timeout ~= nil and inst.sg.timeout > 0 then
            inst.sg:SetTimeout(inst.sg.timeout * ATTACK_TIMEOUT_MULT)
        end
    end
end

if AddStategraphPostInit ~= nil then
    AddStategraphPostInit("wilson_client", PatchAttackState)
end
