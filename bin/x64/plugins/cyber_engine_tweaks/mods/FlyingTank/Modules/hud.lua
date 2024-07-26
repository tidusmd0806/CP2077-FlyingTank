local GameSettings = require('External/GameSettings.lua')
local GameHUD = require('External/GameHUD.lua')
local Utils = require("Tools/utils.lua")
local HUD = {}
HUD.__index = HUD

function HUD:New()
    -- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "HUD")
    --static --
    obj.speed_meter_refresh_rate = 0.05
    -- dynamic --
    obj.vehicle_obj = nil
	-- obj.hud_car_controller = nil

    -- obj.is_speed_meter_shown = false
    obj.key_input_show_hint_event = nil
    obj.key_input_hide_hint_event = nil

    obj.popup_manager = nil

    return setmetatable(obj, self)
end

function HUD:Init(vehicle_obj)

    self.vehicle_obj = vehicle_obj

    if not FlyingTank.is_ready then
        self:SetOverride()
        self:SetObserve()
        GameHUD.Initialize()
    end

end

function HUD:SetOverride()

    if not FlyingTank.is_ready then
        -- Override("gameuiPanzerHUDGameController", "OnSpeedValueChanged", function(this, value, wrapped_method)
        --     print("HUD: gameuiPanzerHUDGameController OnSpeedValueChanged")
        --     wrapped_method(1)
        -- end)
    end

end

function HUD:SetObserve()

    if not FlyingTank.is_ready then
        Observe('PopupsManager', 'OnPlayerAttach', function(this)
            self.popup_manager = this
        end)

    end

end

-- function HUD:ShowMeter()

--     self.hud_car_controller:ShowRequest()
--     self.hud_car_controller:OnCameraModeChanged(true)

--     if self.is_speed_meter_shown then
--         return
--     else
--         self.is_speed_meter_shown = true
--         Cron.Every(self.speed_meter_refresh_rate, {tick = 0}, function(timer)
--             local meter_value = 0    
--             if self.vehicle_obj.is_auto_pilot then
--                 inkTextRef.SetText(self.hud_car_controller.SpeedUnits, FlyingTank.core_obj:GetTranslationText("hud_meter_auto_pilot_display"))
--                 meter_value = math.floor(Vector4.Distance(self.vehicle_obj.auto_pilot_info.dist_pos, Game.GetPlayer():GetWorldPosition()))
--             else
--                 if FlyingTank.user_setting_table.is_unit_km_per_hour then
--                     inkTextRef.SetText(self.hud_car_controller.SpeedUnits, FlyingTank.core_obj:GetTranslationText("hud_meter_kph"))
--                     meter_value = math.floor(self.vehicle_obj.engine_obj.current_speed * (3600 / 1000))
--                 else
--                     inkTextRef.SetText(self.hud_car_controller.SpeedUnits,  FlyingTank.core_obj:GetTranslationText("hud_meter_mph"))
--                     meter_value = math.floor(self.vehicle_obj.engine_obj.current_speed * (3600 / 1609))
--                 end
--             end
--             inkTextRef.SetText(self.hud_car_controller.SpeedValue, meter_value)

--             local power_level = 0
--             if self.vehicle_obj.is_auto_pilot then
--                 local distance = Vector4.Distance(self.vehicle_obj.auto_pilot_info.dist_pos, self.vehicle_obj.auto_pilot_info.start_pos)
--                 power_level = math.floor((1.01 - (meter_value / distance)) * 10)
--             else
--                 if FlyingTank.user_setting_table.flight_mode == Def.FlightMode.Heli then
--                     power_level = math.floor((self.vehicle_obj.engine_obj.lift_force - self.vehicle_obj.engine_obj.min_lift_force) / ((self.vehicle_obj.engine_obj.max_lift_force - self.vehicle_obj.engine_obj.min_lift_force) / 10))
--                 elseif FlyingTank.user_setting_table.flight_mode == Def.FlightMode.Spinner then 
--                     power_level = math.floor(self.vehicle_obj.engine_obj.spinner_horizenal_force / (self.vehicle_obj.engine_obj.max_spinner_horizenal_force / 10))
--                 end
--             end
--             self.hud_car_controller:OnRpmValueChanged(power_level)
--             self.hud_car_controller:EvaluateRPMMeterWidget(power_level)
--             if not self.is_speed_meter_shown then
--                 Cron.Halt(timer)
--             end
--         end)
--     end

-- end

-- function HUD:HideMeter()
--     self.hud_car_controller:HideRequest()
--     self.hud_car_controller:OnCameraModeChanged(false)
--     self.is_speed_meter_shown = false
-- end

-- function HUD:SetCustomHint()
--     local hint_table = {}
--     if FlyingTank.user_setting_table.flight_mode == Def.FlightMode.Heli then
--         hint_table = Utils:ReadJson("Data/heli_key_hint.json")
--     elseif FlyingTank.user_setting_table.flight_mode == Def.FlightMode.Spinner then
--         hint_table = Utils:ReadJson("Data/spinner_key_hint.json")
--     end
--     self.key_input_show_hint_event = UpdateInputHintMultipleEvent.new()
--     self.key_input_hide_hint_event = UpdateInputHintMultipleEvent.new()
--     self.key_input_show_hint_event.targetHintContainer = CName.new("GameplayInputHelper")
--     self.key_input_hide_hint_event.targetHintContainer = CName.new("GameplayInputHelper")
--     for _, hint in ipairs(hint_table) do
--         local input_hint_data = InputHintData.new()
--         input_hint_data.source = CName.new(hint.source)
--         input_hint_data.action = CName.new(hint.action)
--         if hint.holdIndicationType == "FromInputConfig" then
--             input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.FromInputConfig
--         elseif hint.holdIndicationType == "Hold" then
--             input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.Hold
--         elseif hint.holdIndicationType == "Press" then
--             input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.Press
--         else
--             input_hint_data.holdIndicationType = inkInputHintHoldIndicationType.FromInputConfig
--         end
--         input_hint_data.sortingPriority = hint.sortingPriority
--         input_hint_data.enableHoldAnimation = hint.enableHoldAnimation
--         local keys = string.gmatch(hint.localizedLabel, "LocKey#(%d+)")
--         local localizedLabels = {}
--         for key in keys do
--             table.insert(localizedLabels, GetLocalizedText("LocKey#" .. key))
--         end
--         input_hint_data.localizedLabel = table.concat(localizedLabels, "-")
--         self.key_input_show_hint_event:AddInputHint(input_hint_data, true)
--         self.key_input_hide_hint_event:AddInputHint(input_hint_data, false)
--     end
-- end

-- function HUD:ShowCustomHint()
--     self:SetCustomHint()
--     Game.GetUISystem():QueueEvent(self.key_input_show_hint_event)
-- end

-- function HUD:HideCustomHint()
--     Game.GetUISystem():QueueEvent(self.key_input_hide_hint_event)
-- end

function HUD:ShowActionButtons()
    GameSettings.Set('/interface/hud/action_buttons', true)
end

function HUD:HideActionButtons()
    GameSettings.Set('/interface/hud/action_buttons', false)
end

function HUD:ShowRadioPopup()
    if self.popup_manager ~= nil then
        self.popup_manager:SpawnVehicleRadioPopup()
    end
end

return HUD