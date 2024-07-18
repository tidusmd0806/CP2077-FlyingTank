-- local Log = require("Tools/log.lua")
local GameUI = require('External/GameUI.lua')
local Hud = require("Modules/hud.lua")
local Sound = require("Modules/sound.lua")
local Ui = require("Modules/ui.lua")
local Event = {}
Event.__index = Event

function Event:New()

    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "Event")
    obj.vehicle_obj = nil
    obj.hud_obj = Hud:New()
    obj.ui_obj = Ui:New()
    obj.sound_obj = Sound:New()

    -- set default parameters
    obj.is_initial_load = false
    obj.current_situation = Def.Situation.Idel
    obj.is_unlocked_dummy_av = false
    obj.is_in_menu = false
    obj.is_in_popup = false
    obj.is_in_photo = false
    obj.is_locked_operation = false
    obj.selected_seat_index = 1

    return setmetatable(obj, self)

end

function Event:Init(vehicle_obj)

    self.vehicle_obj = vehicle_obj

    self.ui_obj:Init(self.vehicle_obj)
    self.hud_obj:Init(self.vehicle_obj)
    self.sound_obj:Init(self.vehicle_obj)

    if not FlyingTank.is_ready then
        self:SetObserve()
        -- self:SetOverride()
    end

end

function Event:SetObserve()

    GameUI.Observe("MenuOpen", function()
        self.is_in_menu = true
    end)

    GameUI.Observe("MenuClose", function()
        self.is_in_menu = false
    end)

    GameUI.Observe("PopupOpen", function()
        self.is_in_popup = true
    end)

    GameUI.Observe("PopupClose", function()
        self.is_in_popup = false
    end)

    GameUI.Observe("PhotoModeOpen", function()
        self.is_in_photo = true
    end)

    GameUI.Observe("PhotoModeClose", function()
        self.is_in_photo = false
    end)

    GameUI.Observe("SessionStart", function()

        if not self.is_initial_load then
            self.log_obj:Record(LogLevel.Info, "Initial Session start detected")
            self.is_initial_load = true
        else
            self.log_obj:Record(LogLevel.Info, "Session start detected")
            FlyingTank.core_obj:Reset()
        end

        FlyingTank.core_obj:SetFastTravelPosition()

        self.is_unlocked_dummy_av = Game.GetVehicleSystem():IsVehiclePlayerUnlocked(TweakDBID.new(self.ui_obj.dummy_basilisk_aldecaldos_record))
        self.current_situation = Def.Situation.Normal

    end)

    GameUI.Observe("SessionEnd", function()
        self.log_obj:Record(LogLevel.Info, "Session end detected")
        self.current_situation = Def.Situation.Idel
    end)
end

function Event:SetOverride()
    Override("OpenVendorUI", "CreateInteraction", function(this, arg_1, arg_2, arg_3, wrapped_method)
        if this:GetActionName().value == "vehicle_door_quest_locked" and self:IsInEntryArea() then
            self.log_obj:Record(LogLevel.Trace, "Disappear vehicle door quest locked")
            return
        end
        wrapped_method(arg_1, arg_2, arg_3)
    end)
end

function Event:SetSituation(situation)
    if self.current_situation == Def.Situation.Idel then
        return false
    elseif self.current_situation == Def.Situation.Normal and situation == Def.Situation.Landing then
        self.log_obj:Record(LogLevel.Info, "Landing detected")
        self.current_situation = Def.Situation.Landing
        return true
    elseif self.current_situation == Def.Situation.Landing and situation == Def.Situation.Waiting then
        self.log_obj:Record(LogLevel.Info, "Waiting detected")
        self.current_situation = Def.Situation.Waiting
        return true
    elseif (self.current_situation == Def.Situation.Waiting and situation == Def.Situation.InVehicle) then
        self.log_obj:Record(LogLevel.Info, "InVehicle detected")
        self.current_situation = Def.Situation.InVehicle
        return true
    elseif (self.current_situation == Def.Situation.Waiting and situation == Def.Situation.TalkingOff) then
        self.log_obj:Record(LogLevel.Info, "TalkingOff detected")
        self.current_situation = Def.Situation.TalkingOff
        return true
    elseif (self.current_situation == Def.Situation.InVehicle and situation == Def.Situation.Waiting) then
        self.log_obj:Record(LogLevel.Info, "Waiting detected")
        self.current_situation = Def.Situation.Waiting
        return true
    elseif (self.current_situation == Def.Situation.TalkingOff and situation == Def.Situation.Normal) then
        self.log_obj:Record(LogLevel.Info, "Normal detected")
        self.current_situation = Def.Situation.Normal
        return true
    else
        self.log_obj:Record(LogLevel.Critical, "Invalid translating situation")
        return false
    end
end

function Event:CheckAllEvents()

    if self.current_situation == Def.Situation.Normal then
        self:CheckCallPurchasedVehicle()
        self:CheckCallVehicle()
        self:CheckGarage()
        self:CheckAvailableFreeCall()
        self:CheckCommonEvent()
    elseif self.current_situation == Def.Situation.Landing then
        self:CheckLanded()
        self:CheckCommonEvent()
    elseif self.current_situation == Def.Situation.Waiting then
        -- self:CheckInEntryArea()
        self:CheckInAV()
        self:CheckReturnPurchasedVehicle()
        self:CheckReturnVehicle()
        self:CheckCommonEvent()
    elseif self.current_situation == Def.Situation.InVehicle then
        self:CheckInAV()
        self:CheckCollision()
        self:CheckAutoModeChange()
        self:CheckFailAutoPilot()
        self:CheckCustomMappinPosition()
        self:CheckCommonEvent()
    elseif self.current_situation == Def.Situation.TalkingOff then
        self:CheckDespawn()
        self:CheckCommonEvent()
        self:CheckLockedSave()
    end

end

function Event:CheckCommonEvent()

    self:CheckSoundRestriction()

end

function Event:CheckGarage()
    FlyingTank.core_obj:UpdateGarageInfo(false)
end

function Event:CheckAvailableFreeCall()

    if self:IsAvailableFreeCall() and not self.is_unlocked_dummy_av then
        self.log_obj:Record(LogLevel.Info, "Unlock dummy vehicle for free call")
        self.is_unlocked_dummy_av = true
        FlyingTank.core_obj:ActivateDummySummon(true)
    elseif not self:IsAvailableFreeCall() and self.is_unlocked_dummy_av then
        self.log_obj:Record(LogLevel.Info, "Lock dummy vehicle for free call")
        self.is_unlocked_dummy_av = false
        FlyingTank.core_obj:ActivateDummySummon(false)
    end
end

function Event:CheckCallVehicle()
    if FlyingTank.core_obj:GetCallStatus() and not self.vehicle_obj:IsSpawning() then
        self.log_obj:Record(LogLevel.Trace, "Vehicle call detected")
        self.sound_obj:PlaySound("100_call_vehicle")
        self.sound_obj:PlaySound("210_landing")
        self:SetSituation(Def.Situation.Landing)
        self.vehicle_obj:SpawnToSky()
    end
end

function Event:CheckCallPurchasedVehicle()
    if FlyingTank.core_obj:GetPurchasedCallStatus() and not self.vehicle_obj:IsSpawning() then
        self.log_obj:Record(LogLevel.Trace, "Purchased vehicle call detected")
        self.sound_obj:PlaySound("100_call_vehicle")
        self.sound_obj:PlaySound("210_landing")
        self:SetSituation(Def.Situation.Landing)
        self.vehicle_obj:SpawnToSky()
    end
end

function Event:CheckLanded()
    if self.vehicle_obj.position_obj:IsCollision() or self.vehicle_obj.is_landed then
        self.log_obj:Record(LogLevel.Trace, "Landed detected")
        self.sound_obj:StopSound("210_landing")
        self.sound_obj:PlaySound("110_arrive_vehicle")
        self:SetSituation(Def.Situation.Waiting)
        self.vehicle_obj:ChangeDoorState(Def.DoorOperation.Open)
    end
end

function Event:CheckInEntryArea()
    if self.vehicle_obj.position_obj:IsPlayerInEntryArea() then
        self.log_obj:Record(LogLevel.Trace, "InEntryArea detected")
        -- self.hud_obj:ShowChoice(self.selected_seat_index)
    else
        -- self.hud_obj:HideChoice()
    end
end

function Event:CheckInAV()
    if self.vehicle_obj:IsPlayerIn() then
        -- when player take on AV
        if self.current_situation == Def.Situation.Waiting then
            self.log_obj:Record(LogLevel.Info, "Enter In AV")
            SaveLocksManager.RequestSaveLockAdd(CName.new("FlyingTank_IN_AV"))
            self.sound_obj:PlaySound("230_fly_loop")
            self:SetSituation(Def.Situation.InVehicle)
            -- self.hud_obj:HideChoice()
            -- self.vehicle_obj:ChangeDoorState(Def.DoorOperation.Close)
            -- self.hud_obj:ShowMeter()
            -- self.hud_obj:ShowCustomHint()
            -- self.hud_obj:HideActionButtons()
        end
    else
        -- when player take off from AV
        if self.current_situation == Def.Situation.InVehicle then
            self.log_obj:Record(LogLevel.Info, "Exit AV")
            self.sound_obj:StopSound("230_fly_loop")
            self:SetSituation(Def.Situation.Waiting)
            -- self.hud_obj:HideMeter()
            -- self.hud_obj:HideCustomHint()
            -- self.hud_obj:ShowActionButtons()
            self:StopRadio()
            self:UnsetMappin()
            SaveLocksManager.RequestSaveLockRemove(CName.new("FlyingTank_IN_AV"))
        end
    end
end

function Event:CheckCollision()
    if self.vehicle_obj.is_collision then
        self.log_obj:Record(LogLevel.Debug, "Collision detected")
        local material = self.vehicle_obj.position_obj.collision_trace_result.material.value
        if not self.vehicle_obj.engine_obj:IsInFalling() then
            if string.find(material, "concrete") then
                self.sound_obj:PlaySound("331_crash_concrete")
            elseif string.find(material, "metal") then
                self.sound_obj:PlaySound("332_crash_metal")
            elseif string.find(material, "glass") then
                self.sound_obj:PlaySound("333_crash_wood")
            else
                self.sound_obj:PlaySound("330_crash_default")
            end
        end
    end
end

function Event:CheckReturnVehicle()
    if FlyingTank.core_obj:GetCallStatus() then
        self.log_obj:Record(LogLevel.Trace, "Vehicle return detected")
        self.sound_obj:PlaySound("240_leaving")
        self.sound_obj:PlaySound("104_call_vehicle")
        self:SetSituation(Def.Situation.TalkingOff)
        -- self.hud_obj:HideChoice()
        self.vehicle_obj:ChangeDoorState(Def.DoorOperation.Close)
        self.vehicle_obj:DespawnFromGround()
    end
end

function Event:CheckReturnPurchasedVehicle()
    if FlyingTank.core_obj:GetPurchasedCallStatus() then
        self.log_obj:Record(LogLevel.Trace, "Purchased vehicle return detected")
        self.sound_obj:PlaySound("240_leaving")
        self.sound_obj:PlaySound("104_call_vehicle")
        self:SetSituation(Def.Situation.TalkingOff)
        -- self.hud_obj:HideChoice()
        self.vehicle_obj:ChangeDoorState(Def.DoorOperation.Close)
        self.vehicle_obj:DespawnFromGround()
    end
end

function Event:CheckDespawn()
    if self.vehicle_obj:IsDespawned() then
        self.log_obj:Record(LogLevel.Trace, "Despawn detected")
        self.sound_obj:StopSound("240_leaving")
        self:SetSituation(Def.Situation.Normal)
        FlyingTank.core_obj:Reset()
    end
end

function Event:CheckAutoModeChange()
    if self:IsAutoMode() and not self.is_locked_operation then
        self.is_locked_operation = true
    elseif not self:IsAutoMode() and self.is_locked_operation then
        self.is_locked_operation = false
        self.hud_obj:ShowArrivalDisplay()
    end

end

function Event:CheckFailAutoPilot()
    if self.vehicle_obj:IsFailedAutoPilot() then
        self.hud_obj:ShowInterruptAutoPilotDisplay()
    end
end

function Event:CheckCustomMappinPosition()

    if self.vehicle_obj.is_auto_pilot then
        return
    end
    local success, mappin = pcall(function() return FlyingTank.core_obj.mappin_controller:GetMappin() end)
    if not success then
        self.log_obj:Record(LogLevel.Debug, "Mappin is not found")
        FlyingTank.core_obj.is_custom_mappin = false
        if self.stored_mappin_pos == nil then
            return
        end
    else
        FlyingTank.core_obj.is_custom_mappin = true
    end
    local mappin_pos = mappin:GetWorldPosition()
    if Vector4.Distance(FlyingTank.core_obj.current_custom_mappin_position, mappin_pos) ~= 0 then
        FlyingTank.core_obj:SetCustomMappin(mappin)
    end

end

function Event:CheckLockedSave()
    local res, reason = Game.IsSavingLocked()
    if res then
        self.log_obj:Record(LogLevel.Info, "Locked save detected. Remove lock")
        SaveLocksManager.RequestSaveLockRemove(CName.new("FlyingTank_IN_AV"))
    end

end

function Event:StopRadio()
    self.vehicle_obj.radio_obj:Stop()
end

function Event:UnsetMappin()
    FlyingTank.core_obj.is_custom_mappin = false
    FlyingTank.core_obj:RemoveFavoriteMappin()
end

function Event:IsAvailableFreeCall()
    return FlyingTank.user_setting_table.is_free_summon_mode
end

function Event:IsNotSpawned()
    if self.current_situation == Def.Situation.Normal then
        return true
    else
        return false
    end
end

function Event:IsWaiting()
    if self.current_situation == Def.Situation.Waiting then
        return true
    else
        return false
    end
end

function Event:IsInEntryArea()
    if self.current_situation == Def.Situation.Waiting and self.vehicle_obj.position_obj:IsPlayerInEntryArea() then
        return true
    else
        return false

    end
end

function Event:IsInVehicle()
    if self.current_situation == Def.Situation.InVehicle and self.vehicle_obj:IsPlayerIn() then
        return true
    else
        return false
    end
end

function Event:IsAutoMode()
    if self.vehicle_obj.is_auto_pilot then
        return true
    else
        return false
    end
end

function Event:IsInMenuOrPopupOrPhoto()
    if self.is_in_menu or self.is_in_popup or self.is_in_photo then
        return true
    else
        return false
    end
end

function Event:IsAllowedEntry()
    return self.is_allowed_entry
end

function Event:ChangeDoor()
    if self.current_situation == Def.Situation.InVehicle then
        self.vehicle_obj:ChangeDoorState(Def.DoorOperation.Change)
    end
end

function Event:EnterVehicle()
    if self:IsInEntryArea()then
        self.vehicle_obj:Mount()
    end
end

function Event:ExitVehicle()
    if self:IsInVehicle() then
        self.vehicle_obj:Unmount()
    end
end

function Event:ToggleAutoMode()
    if self:IsInVehicle() then
        if not self.vehicle_obj.is_auto_pilot then
            self.hud_obj:ShowAutoModeDisplay()
            self.is_locked_operation = true
            self.vehicle_obj:AutoPilot()
        elseif not self.vehicle_obj.is_leaving then
            self.hud_obj:ShowDriveModeDisplay()
            self.is_locked_operation = false
            self.vehicle_obj:InterruptAutoPilot()
        end
    end
end

function Event:ShowRadioPopup()
    if self:IsInVehicle() then
        self.hud_obj:ShowRadioPopup()
    end
end

function Event:SelectChoice(direction)
    local max_seat_index = #self.vehicle_obj.all_models[FlyingTank.model_index].actual_allocated_seat
    if self:IsInEntryArea() then
        if direction == Def.ActionList.SelectUp then
            self.selected_seat_index = self.selected_seat_index - 1
            if self.selected_seat_index < 1 then
                self.selected_seat_index = max_seat_index

            end
        elseif direction == Def.ActionList.SelectDown then
            self.selected_seat_index = self.selected_seat_index + 1
            if self.selected_seat_index > max_seat_index then
                self.selected_seat_index = 1
            end
        else
            self.log_obj:Record(LogLevel.Critical, "Invalid direction detected")
            return
        end
        self.vehicle_obj.seat_index = self.selected_seat_index
    end
end

function Event:CheckSoundRestriction()
    if not FlyingTank.user_setting_table.is_mute_all and not FlyingTank.user_setting_table.is_mute_flight then
        self.sound_obj:SetRestriction(Def.SoundRestrictionLevel.None)
    else
        if FlyingTank.user_setting_table.is_mute_all then
            self.sound_obj:SetRestriction(Def.SoundRestrictionLevel.Mute)
            self.sound_obj:Mute()
        elseif FlyingTank.user_setting_table.is_mute_flight then
            self.sound_obj:SetRestriction(Def.SoundRestrictionLevel.PriorityRadio)
            self.sound_obj:PartialMute(200, 300)
        end
    end
end

return Event
