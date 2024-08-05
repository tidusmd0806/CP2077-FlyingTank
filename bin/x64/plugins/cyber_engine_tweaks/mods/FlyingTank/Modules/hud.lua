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
    obj.shown_max_pitch = 35
    -- dynamic --
    obj.vehicle_obj = nil
    obj.key_input_show_hint_event = nil
    obj.key_input_hide_hint_event = nil

    obj.popup_manager = nil
    obj.hud_tank_controller = nil

    obj.kill_count = 0

    return setmetatable(obj, self)
end

function HUD:Init(vehicle_obj)

    self.vehicle_obj = vehicle_obj

    if not FlyingTank.is_ready then
        self:SetOverride()
        self:SetObserve()
        self:PreTankHUD()
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

        Observe('gameuiPanzerHUDGameController', 'OnInitialize', function(this)
            self.hud_tank_controller = this
        end)

        Observe('NPCPuppet', 'SendAfterDeathOrDefeatEvent', function(this)
            self.kill_count = self.kill_count + 1
        end)
    end

end

function HUD:PreTankHUD()

    -- gauge normal color settings
    self.gauge_normal_color = HDRColor.new()
    self.gauge_normal_color.Red = 0.369
    self.gauge_normal_color.Green = 0.965
    self.gauge_normal_color.Blue = 1.000
    self.gauge_normal_color.Alpha = 1.000

    -- gauge warning color settings
    self.gauge_waring_color = HDRColor.new()
    self.gauge_waring_color.Red = 1.369
    self.gauge_waring_color.Green = 0.965
    self.gauge_waring_color.Blue = 1.000
    self.gauge_waring_color.Alpha = 1.000

end

function HUD:UpdateTankHUD()
    local root_widget = self.hud_tank_controller.root

    if root_widget == nil then
        return
    end

    -- Attitude Indicator
    local attitude_indicator = root_widget:GetWidget(CName.new("ruler_right")):GetWidget(CName.new("value"))
    local attitude_num = self.vehicle_obj.position_obj:GetPosition().z
    attitude_indicator:SetText(tostring(math.floor(attitude_num)))

    -- Left Bottom Gauge
    local boost_gauge_widget = root_widget:GetWidget(CName.new("boost"))
    local boost_gauge_header = boost_gauge_widget:GetWidget(CName.new("header"))
    local boost_gauge_slide_bar = boost_gauge_widget:GetWidget(CName.new("inkMaskWidget48"))
    local boost_gauge_bar_base = boost_gauge_widget:GetWidget(0)
    local boost_gauge_max_value = boost_gauge_widget:GetWidget(5)
    local pitch_value = self.vehicle_obj.position_obj:GetEulerAngles().pitch
    local pitch_value_int = math.floor(pitch_value)
    boost_gauge_header:SetText(FlyingTank.core_obj:GetTranslationText("hud_pitch_header") .. "[" .. tostring(pitch_value_int) .. "]")
    if pitch_value_int > self.shown_max_pitch then
        pitch_value_int = self.shown_max_pitch
    elseif pitch_value_int < -self.shown_max_pitch then
        pitch_value_int = -self.shown_max_pitch
    end
    local num = self.shown_max_pitch - math.abs(pitch_value_int)
    boost_gauge_slide_bar:SetMargin(-1801.25 - num * 10, 895, 0, 0)
    if pitch_value > 0 then
        if pitch_value > self.shown_max_pitch / 2 then
            boost_gauge_bar_base:SetTintColor(self.gauge_waring_color)
        else
            boost_gauge_bar_base:SetTintColor(self.gauge_normal_color)
        end
        boost_gauge_max_value:SetText(tostring(self.shown_max_pitch))
    else
        if pitch_value < -self.shown_max_pitch / 2 then
            boost_gauge_bar_base:SetTintColor(self.gauge_waring_color)
        else
            boost_gauge_bar_base:SetTintColor(self.gauge_normal_color)
        end
        boost_gauge_max_value:SetText(tostring(-self.shown_max_pitch))
    end

    -- YAW Indicator
    local yaw_indicator_header = root_widget:GetWidget(CName.new("ruler_yaw")):GetWidget(CName.new("yaw_descr"))
    local yaw_indicator_value = root_widget:GetWidget(CName.new("ruler_yaw")):GetWidget(CName.new("yaw_hori")):GetWidget(CName.new("yawCounter"))
    local yaw_value = self.vehicle_obj.position_obj:GetEulerAngles().yaw
    local yaw_value_int = math.floor(yaw_value)
    if yaw_value_int < 0 then
        yaw_value_int = -yaw_value_int
    elseif yaw_value_int > 0 then
        yaw_value_int = 360 - yaw_value_int
    end
    yaw_indicator_header:SetText(FlyingTank.core_obj:GetTranslationText("hud_yaw_header"))
    yaw_indicator_value:SetText(tostring(yaw_value_int))

    -- Right Bottom Text
    local right_bottom_text_parent = root_widget:GetWidget(CName.new("missile"))
    local right_bottom_text_top = right_bottom_text_parent:GetWidget(CName.new("header"))
    local right_bottom_text_middle = right_bottom_text_parent:GetWidget(3)
    local right_bottom_text_bottom = right_bottom_text_parent:GetWidget(CName.new("0"))
    right_bottom_text_middle:SetText(tostring(self.kill_count))

end

function HUD:ShowRadioPopup()
    if self.popup_manager ~= nil then
        self.popup_manager:SpawnVehicleRadioPopup()
    end
end

return HUD