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
    obj.hud_mode_list = {
        "District",
        "KillCounter"
    }
    -- dynamic --
    obj.vehicle_obj = nil
    obj.popup_manager = nil
    obj.hud_tank_controller = nil
    obj.fan_speed = 50
    obj.kill_count = 0
    obj.vehicle_hp = 100

    return setmetatable(obj, self)
end

function HUD:Init(vehicle_obj)

    self.vehicle_obj = vehicle_obj

    self.kill_count = 0

    if not FlyingTank.is_ready then
        self:SetOverride()
        self:SetObserve()
        self:PreTankHUD()
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
            if this.isPolice then
                print("Police")
            end
        end)

        Observe("VehicleComponent", "EvaluateDamageLevel", function(this, destruction)
            if this.mounted then
                self.vehicle_hp = destruction
            end
        end)

        Override("PanzerHUDGameController", "OnStatsChanged", function(this, value, wrapped_method)
            -- To prevent the game from changing the HP value
            return
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

    -- gauge pre warning color settings
    self.gauge_pre_waring_color = HDRColor.new()
    self.gauge_pre_waring_color.Red = 1.000
    self.gauge_pre_waring_color.Green = 1.000
    self.gauge_pre_waring_color.Blue = 0.800
    self.gauge_pre_waring_color.Alpha = 1.000

    -- gauge warning color settings
    self.gauge_waring_color = HDRColor.new()
    self.gauge_waring_color.Red = 1.369
    self.gauge_waring_color.Green = 0.965
    self.gauge_waring_color.Blue = 1.000
    self.gauge_waring_color.Alpha = 1.000

end

function HUD:UpdateTankHUD()

    if self.hud_tank_controller == nil then
        return
    end
    local root_widget = self.hud_tank_controller.root

    if root_widget == nil then
        return
    end

    if FlyingTank.user_setting_table.is_active_hud == false and FlyingTank.is_active_hud ~= false then
        self.hud_tank_controller:TurnOff()
        FlyingTank.is_active_hud = false
        return
    elseif FlyingTank.user_setting_table.is_active_hud == true and FlyingTank.is_active_hud ~= true then
        self.hud_tank_controller:TurnOn()
        FlyingTank.is_active_hud = true
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

    -- Both Side Fan Speed
    local left_fan_speed = root_widget:GetWidget(CName.new("intake_fans-l")):GetWidget(CName.new("L-percent"))
    local right_fan_speed = root_widget:GetWidget(CName.new("intake_fans-r")):GetWidget(CName.new("R-percent"))
    local fan_speed_int = math.floor(self.fan_speed)
    left_fan_speed:SetText(tostring(fan_speed_int).. "%")
    right_fan_speed:SetText(tostring(fan_speed_int).. "%")

    -- Right Bottom Text
    local right_bottom_text_parent = root_widget:GetWidget(CName.new("missile"))
    local right_bottom_text_top = right_bottom_text_parent:GetWidget(CName.new("header"))
    local right_bottom_text_middle = right_bottom_text_parent:GetWidget(3)
    local right_bottom_text_bottom = right_bottom_text_parent:GetWidget(CName.new("0"))
    if self.hud_mode_list[FlyingTank.user_setting_table.hud_mode] == "District" then
        local district_list = FlyingTank.core_obj:GetCurrentDistrict()
        local district_list_num = #district_list
        if district_list_num >= 1 then
            right_bottom_text_top:SetText(" ")
            right_bottom_text_top:SetFontSize(29)
            right_bottom_text_middle:SetText(district_list[1])
            right_bottom_text_middle:SetFontSize(44)
        end
        if district_list_num >= 2 then
            right_bottom_text_top:SetText(district_list[2])
        end
        local x = string.format("%.2f", self.vehicle_obj.position_obj:GetPosition().x)
        local y = string.format("%.2f", self.vehicle_obj.position_obj:GetPosition().y)
        local z = string.format("%.2f", self.vehicle_obj.position_obj:GetPosition().z)
        right_bottom_text_bottom:SetText("X: " .. x .. "  Y: " .. y .. "  Z: " .. z)
        right_bottom_text_bottom:SetFontSize(18)
    elseif self.hud_mode_list[FlyingTank.user_setting_table.hud_mode] == "KillCounter" then
        right_bottom_text_top:SetText(FlyingTank.core_obj:GetTranslationText("hud_kill_counter_header"))
        right_bottom_text_top:SetFontSize(22)
        right_bottom_text_middle:SetText(tostring(self.kill_count))
        right_bottom_text_middle:SetFontSize(97)
        right_bottom_text_bottom:SetText(" ")
        right_bottom_text_bottom:SetFontSize(22)
    end

    -- HP Gauge
    local hp_gauge_widget = root_widget:GetWidget(CName.new("HP"))
    local hp_header_value = hp_gauge_widget:GetWidget(CName.new("headerPanel")):GetWidget(CName.new("valueContainer")):GetWidget(CName.new("value"))
    local hp_header_plate = hp_gauge_widget:GetWidget(CName.new("headerPanel")):GetWidget(CName.new("valueContainer")):GetWidget(CName.new("plate"))
    local hp_gauge_slide_bar = hp_gauge_widget:GetWidget(CName.new("inkMaskWidget48"))
    local hp_gauge_bar_base = hp_gauge_widget:GetWidget(0)
    local hp_int = math.floor(self.vehicle_hp)
    hp_header_value:SetText(tostring(hp_int) .. "/100")
    local hp_remain = (680 / 100) * hp_int
    hp_gauge_slide_bar:SetMargin(-2203 + hp_remain, -915.83, 0, 0)
    if hp_int < 20 then
        hp_gauge_bar_base:SetTintColor(self.gauge_waring_color)
        hp_header_plate:SetTintColor(self.gauge_waring_color)
    elseif hp_int < 50 then
        hp_gauge_bar_base:SetTintColor(self.gauge_pre_waring_color)
        hp_header_plate:SetTintColor(self.gauge_pre_waring_color)
    else
        hp_gauge_bar_base:SetTintColor(self.gauge_normal_color)
        hp_header_plate:SetTintColor(self.gauge_normal_color)
    end


end

function HUD:ShowRadioPopup()
    if self.popup_manager ~= nil then
        self.popup_manager:SpawnVehicleRadioPopup()
    end
end

return HUD