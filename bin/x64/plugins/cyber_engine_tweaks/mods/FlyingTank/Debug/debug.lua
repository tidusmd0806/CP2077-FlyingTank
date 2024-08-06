local Utils = require("Tools/utils.lua")
local Debug = {}
Debug.__index = Debug

function Debug:New(core_obj)
    local obj = {}
    obj.core_obj = core_obj

    -- set parameters
    obj.is_set_observer = false
    obj.is_im_gui_rw_count = false
    obj.is_im_gui_situation = false
    obj.is_im_gui_player_position = false
    obj.is_im_gui_av_position = false
    obj.is_im_gui_heli_info = false
    obj.is_im_gui_spinner_info = false
    obj.is_im_gui_engine_info = false
    obj.is_im_gui_sound_check = false
    obj.selected_sound = "100_call_vehicle"
    obj.is_im_gui_mappin_position = false
    obj.is_im_gui_model_type_status = false
    obj.is_im_gui_auto_pilot_status = false
    obj.is_im_gui_change_auto_setting = false
    obj.is_im_gui_radio_info = false
    obj.is_im_gui_measurement = false
    obj.is_exist_av_1 = false
    obj.is_exist_av_2 = false
    obj.is_exist_av_3 = false
    obj.is_exist_av_4 = false
    obj.is_exist_av_5 = false

    return setmetatable(obj, self)
end

function Debug:ImGuiMain()

    ImGui.Begin("FlyingTank DEBUG WINDOW")
    ImGui.Text("Debug Mode : On")

    self:SetObserver()
    self:SetLogLevel()
    self:SelectPrintDebug()
    self:ImGuiShowRWCount()
    self:ImGuiSituation()
    self:ImGuiPlayerPosition()
    self:ImGuiAVPosition()
    self:ImGuiSoundCheck()
    self:ImGuiRadioInfo()
    self:ImGuiMeasurement()
    self:ImGuiExcuteFunction()

    ImGui.End()

end

function Debug:SetObserver()

    if not self.is_set_observer then
        -- reserved
    end
    self.is_set_observer = true

    if self.is_set_observer then
        ImGui.SameLine()
        ImGui.Text("Observer : On")
    end

end

function Debug:SetLogLevel()
    local selected = false
    if ImGui.BeginCombo("LogLevel", Utils:GetKeyFromValue(LogLevel, MasterLogLevel)) then
		for _, key in ipairs(Utils:GetKeys(LogLevel)) do
			if Utils:GetKeyFromValue(LogLevel, MasterLogLevel) == key then
				selected = true
			else
				selected = false
			end
			if(ImGui.Selectable(key, selected)) then
				MasterLogLevel = LogLevel[key]
			end
		end
		ImGui.EndCombo()
	end
end

function Debug:SelectPrintDebug()
    PrintDebugMode = ImGui.Checkbox("Print Debug Mode", PrintDebugMode)
end

function Debug:ImGuiShowRWCount()
    self.is_im_gui_rw_count = ImGui.Checkbox("[ImGui] R/W Count", self.is_im_gui_rw_count)
    if self.is_im_gui_rw_count then
        ImGui.Text("Read : " .. READ_COUNT .. ", Write : " .. WRITE_COUNT)
    end
end

function Debug:ImGuiSituation()
    self.is_im_gui_situation = ImGui.Checkbox("[ImGui] Current Situation", self.is_im_gui_situation)
    if self.is_im_gui_situation then
        ImGui.Text("Current Situation : " .. self.core_obj.event_obj.current_situation)
    end
end

function Debug:ImGuiPlayerPosition()
    self.is_im_gui_player_position = ImGui.Checkbox("[ImGui] Player Position Angle", self.is_im_gui_player_position)
    if self.is_im_gui_player_position then
        local x = string.format("%.2f", Game.GetPlayer():GetWorldPosition().x)
        local y = string.format("%.2f", Game.GetPlayer():GetWorldPosition().y)
        local z = string.format("%.2f", Game.GetPlayer():GetWorldPosition().z)
        ImGui.Text("[world]X:" .. x .. ", Y:" .. y .. ", Z:" .. z)
        local roll = string.format("%.2f", Game.GetPlayer():GetWorldOrientation():ToEulerAngles().roll)
        local pitch = string.format("%.2f", Game.GetPlayer():GetWorldOrientation():ToEulerAngles().pitch)
        local yaw = string.format("%.2f", Game.GetPlayer():GetWorldOrientation():ToEulerAngles().yaw)
        ImGui.Text("[world]Roll:" .. roll .. ", Pitch:" .. pitch .. ", Yaw:" .. yaw)
    end
end

function Debug:ImGuiAVPosition()
    self.is_im_gui_av_position = ImGui.Checkbox("[ImGui] AV Position Angle", self.is_im_gui_av_position)
    if self.is_im_gui_av_position then
        if self.core_obj.vehicle_obj.position_obj.entity == nil then
            return
        end
        local x = string.format("%.2f", self.core_obj.vehicle_obj.position_obj:GetPosition().x)
        local y = string.format("%.2f", self.core_obj.vehicle_obj.position_obj:GetPosition().y)
        local z = string.format("%.2f", self.core_obj.vehicle_obj.position_obj:GetPosition().z)
        local roll = string.format("%.2f", self.core_obj.vehicle_obj.position_obj:GetEulerAngles().roll)
        local pitch = string.format("%.2f", self.core_obj.vehicle_obj.position_obj:GetEulerAngles().pitch)
        local yaw = string.format("%.2f", self.core_obj.vehicle_obj.position_obj:GetEulerAngles().yaw)
        ImGui.Text("X: " .. x .. ", Y: " .. y .. ", Z: " .. z)
        ImGui.Text("Roll:" .. roll .. ", Pitch:" .. pitch .. ", Yaw:" .. yaw)
    end
end

function Debug:ImGuiHeliInfo()
    self.is_im_gui_heli_info = ImGui.Checkbox("[ImGui] Heli Info", self.is_im_gui_heli_info)
    if self.is_im_gui_heli_info then
        if self.core_obj.vehicle_obj.position_obj.entity == nil then
            return
        end
        local f = string.format("%.2f", self.core_obj.vehicle_obj.engine_obj.lift_force)
        local v_x = string.format("%.2f", self.core_obj.vehicle_obj.engine_obj.horizenal_x_speed)
        local v_y = string.format("%.2f", self.core_obj.vehicle_obj.engine_obj.horizenal_y_speed)
        local v_z = string.format("%.2f", self.core_obj.vehicle_obj.engine_obj.vertical_speed)
        ImGui.Text("F: " .. f .. ", v_x: " .. v_x .. ", v_y: " .. v_y .. ", v_z: " .. v_z)
    end
end

function Debug:ImGuiSpinnerInfo()
    self.is_im_gui_spinner_info = ImGui.Checkbox("[ImGui] Spinner Info", self.is_im_gui_spinner_info)
    if self.is_im_gui_spinner_info then
        if self.core_obj.vehicle_obj.position_obj.entity == nil then
            return
        end
        local f_h = string.format("%.2f", self.core_obj.vehicle_obj.engine_obj.spinner_horizenal_force)
        local f_v = string.format("%.2f", self.core_obj.vehicle_obj.engine_obj.spinner_vertical_force)
        local v_x = string.format("%.2f", self.core_obj.vehicle_obj.engine_obj.horizenal_x_speed)
        local v_y = string.format("%.2f", self.core_obj.vehicle_obj.engine_obj.horizenal_y_speed)
        local v_z = string.format("%.2f", self.core_obj.vehicle_obj.engine_obj.vertical_speed)
        local v_angle = string.format("%.2f", self.core_obj.vehicle_obj.engine_obj.spinner_speed_angle * 180 / Pi())
        ImGui.Text("F_h: " .. f_h .. ", F_v : " .. f_v)
        ImGui.Text("v_x: " .. v_x .. ", v_y: " .. v_y .. ", v_z: " .. v_z .. ", v_angle: " .. v_angle)
    end
end

function Debug:ImGuiSoundCheck()
    self.is_im_gui_sound_check = ImGui.Checkbox("[ImGui] Sound Check", self.is_im_gui_sound_check)
    if self.is_im_gui_sound_check then
        if ImGui.BeginCombo("##Sound List", self.selected_sound) then
            for key, _ in pairs(self.core_obj.event_obj.sound_obj.sound_data) do
                if (ImGui.Selectable(key, (self.selected_sound==key))) then
                    self.selected_sound = key
                end
            end
            ImGui.EndCombo()
        end

        if ImGui.Button("Play", 150, 60) then
            self.core_obj.event_obj.sound_obj:PlaySound(self.selected_sound)
        end

        if ImGui.Button("Stop", 150, 60) then
            self.core_obj.event_obj.sound_obj:StopSound(self.selected_sound)
        end
    end
end

function Debug:ImGuiRadioInfo()
    self.is_im_gui_radio_info = ImGui.Checkbox("[ImGui] Radio Info", self.is_im_gui_radio_info)
    if self.is_im_gui_radio_info then
        local volume = self.core_obj.vehicle_obj.radio_obj:GetVolume()
        local entity_num = #self.core_obj.vehicle_obj.radio_obj.radio_entity_list
        local station_index = self.core_obj.vehicle_obj.radio_obj:GetPlayingStationIndex()
        local station_name = CName("No Play")
        if station_index >= 0 then
            station_name = RadioStationDataProvider.GetStationNameByIndex(station_index)
        end
        local track_name = GetLocalizedText(LocKeyToString(self.core_obj.vehicle_obj.radio_obj:GetTrackName()))
        local is_playing = self.core_obj.vehicle_obj.radio_obj.is_playing
        local is_opened_radio_popup = self.core_obj.is_opened_radio_popup
        local radio_port_index = self.core_obj.current_station_index
        local radio_port_volume = self.core_obj.current_radio_volume
        ImGui.Text("Radio Port Index : " .. radio_port_index .. ", Radio Port Volume : " .. radio_port_volume)
        ImGui.Text("Actual Volume : " .. volume .. ", Entity Num : " .. entity_num)
        ImGui.Text("Actual Station Index : " .. station_index .. ", Station Name : " .. station_name.value)
        ImGui.Text("Track Name : " .. track_name)
        ImGui.Text("Is Playing : " .. tostring(is_playing) .. ", Is Radio Popup : " .. tostring(is_opened_radio_popup))
    end
end

function Debug:ImGuiMeasurement()
    self.is_im_gui_measurement = ImGui.Checkbox("[ImGui] Measurement", self.is_im_gui_measurement)
    if self.is_im_gui_measurement then
        -- local res_x, res_y = GetDisplayResolution()
        -- ImGui.SetNextWindowPos((res_x / 2) - 20, (res_y / 2) - 20)
        -- ImGui.SetNextWindowSize(40, 40)
        -- ImGui.SetNextWindowSizeConstraints(40, 40, 40, 40)
        -- ---
        -- ImGui.PushStyleVar(ImGuiStyleVar.WindowRounding, 10)
        -- ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 5)
        -- ---
        -- ImGui.Begin("FlyingTankDebugCrosshair", ImGuiWindowFlags.NoMove + ImGuiWindowFlags.NoCollapse + ImGuiWindowFlags.NoTitleBar + ImGuiWindowFlags.NoResize)
        -- ImGui.End()
        -- ---
        -- ImGui.PopStyleVar(2)
        -- ImGui.PopStyleColor(1)
        local look_at_pos = Game.GetTargetingSystem():GetLookAtPosition(Game.GetPlayer())
        if self.core_obj.vehicle_obj.position_obj.entity == nil then
            return
        end
        local origin = self.core_obj.vehicle_obj.position_obj:GetPosition()
        local right = self.core_obj.vehicle_obj.position_obj.entity:GetWorldRight()
        local forward = self.core_obj.vehicle_obj.position_obj.entity:GetWorldForward()
        local up = self.core_obj.vehicle_obj.position_obj.entity:GetWorldUp()
        local relative = Vector4.new(look_at_pos.x - origin.x, look_at_pos.y - origin.y, look_at_pos.z - origin.z, 1)
        local x = Vector4.Dot(relative, right)
        local y = Vector4.Dot(relative, forward)
        local z = Vector4.Dot(relative, up)
        local absolute_position_x = string.format("%.2f", x)
        local absolute_position_y = string.format("%.2f", y)
        local absolute_position_z = string.format("%.2f", z)
        ImGui.Text("[LookAt]X:" .. absolute_position_x .. ", Y:" .. absolute_position_y .. ", Z:" .. absolute_position_z) 
    end
end

function Debug:ImGuiExcuteFunction()
    if ImGui.Button("TF1") then
        -- atitude
        local root_widget = self.core_obj.event_obj.hud_obj.hud_tank_controller.root
        local child_widget = root_widget:GetWidget(CName.new("ruler_right"))
        local child_widget_2 = child_widget:GetWidget(CName.new("value"))
        local num = math.random(0, 1000)
        child_widget_2:SetText(tostring(num))
        print("Excute Test Function 1")
    end
    ImGui.SameLine()
    if ImGui.Button("TF2") then
        local root_widget = self.core_obj.event_obj.hud_obj.hud_tank_controller.root
        local child_widget = root_widget:GetWidget(CName.new("boost"))
        local child_widget_header = child_widget:GetWidget(CName.new("header"))
        local child_widget_bar = child_widget:GetWidget(CName.new("inkMaskWidget48"))
        local child_widget_bar_base = child_widget:GetWidget(0)
        local child_widget_bar_max = child_widget:GetWidget(5)
        child_widget_header:SetText("aaa")
        local num = math.random(0, 35)
        child_widget_bar:SetMargin(-1801.25 - num * 10, 895, 0, 0)
        local color = HDRColor.new()
        color.Red = 1.369
        color.Green = 0.965
        color.Blue = 1.000
        color.Alpha = 1.000
        child_widget_bar_base:SetTintColor(color) -- default : 0.369, 0.965, 1.000, 1.000
        child_widget_bar_max:SetText(tostring(num))
        print("Excute Test Function 2")
    end
    ImGui.SameLine()
    if ImGui.Button("TF3") then
        local root_widget = self.core_obj.event_obj.hud_obj.hud_tank_controller.root
        local child_widget = root_widget:GetWidget(CName.new("missile"))
        local child_widget_header = child_widget:GetWidget(CName.new("header"))
        local child_widget_text_1 = child_widget:GetWidget(3)
        local child_widget_text_2 = child_widget:GetWidget(CName.new("0"))
        child_widget_header:SetText("bbb")
        child_widget_text_1:SetText("ccc")
        child_widget_text_2:SetText("ddd")
        print("Excute Test Function 3")
    end
    ImGui.SameLine()
    if ImGui.Button("TF4") then
        local root_widget = self.core_obj.event_obj.hud_obj.hud_tank_controller.root
        local child_widget = root_widget:GetWidget(CName.new("ruler_yaw"))
        local child_widget_header = child_widget:GetWidget(CName.new("yaw_descr"))
        child_widget_header:SetText("eee")
        local child_widget_2 = child_widget:GetWidget(CName.new("yaw_hori"))
        local child_widget_3 = child_widget_2:GetWidget(CName.new("yawCounter"))
        local num = math.random(-100, 100)
        child_widget_3:SetText(tostring(num))
        print("Excute Test Function 4")
    end
    ImGui.SameLine()
    if ImGui.Button("TF5") then
        local root_widget = self.core_obj.event_obj.hud_obj.hud_tank_controller.root
        local child_widget_r = root_widget:GetWidget(CName.new("intake_fans-r"))
        local child_widget_right = child_widget_r:GetWidget(CName.new("R-percent"))
        local num = math.random(0, 100)
        child_widget_right:SetText(tostring(num) .. "%")
        local child_widget_l = root_widget:GetWidget(CName.new("intake_fans-l"))
        local child_widget_left = child_widget_l:GetWidget(CName.new("L-percent"))
        local num = math.random(0, 100)
        child_widget_left:SetText(tostring(num) .. "%")
        print("Excute Test Function 5")
    end
    if ImGui.Button("TF6") then
        local vec = Vector3.new(0, 0, 10)
        local angle_vec = Vector3.new(0, 0, 0)
        print(self.core_obj.vehicle_obj.position_obj.fly_tank_system:AddLinelyVelocity(vec, angle_vec))

        print("Excute Test Function 6")
    end
    ImGui.SameLine()
    if ImGui.Button("TF7") then
        local veh = Game.GetMountedVehicle(Game.GetPlayer())
        local eular_angle = veh:GetWorldOrientation():ToEulerAngles()
        function eulerAngleChange(a, b, c, p, q, r)
            -- オイラー角をラジアンに変換
            local rad_a = math.rad(a)
            local rad_b = math.rad(b)
            local rad_c = math.rad(c)
            local rad_p = math.rad(p)
            local rad_q = math.rad(q)
            local rad_r = math.rad(r)
        
            -- sinとcosを計算
            local cos_a, sin_a = math.cos(rad_a), math.sin(rad_a)
            local cos_b, sin_b = math.cos(rad_b), math.sin(rad_b)
            local cos_c, sin_c = math.cos(rad_c), math.sin(rad_c)
            local cos_p, sin_p = math.cos(rad_p), math.sin(rad_p)
            local cos_q, sin_q = math.cos(rad_q), math.sin(rad_q)
            local cos_r, sin_r = math.cos(rad_r), math.sin(rad_r)
        
            -- 回転行列を計算
            local R1 = {
                {cos_a * cos_b, cos_a * sin_b * sin_c - sin_a * cos_c, cos_a * sin_b * cos_c + sin_a * sin_c},
                {sin_a * cos_b, sin_a * sin_b * sin_c + cos_a * cos_c, sin_a * sin_b * cos_c - cos_a * sin_c},
                {-sin_b, cos_b * sin_c, cos_b * cos_c}
            }
        
            local R2 = {
                {cos_p * cos_q, cos_p * sin_q * sin_r - sin_p * cos_r, cos_p * sin_q * cos_r + sin_p * sin_r},
                {sin_p * cos_q, sin_p * sin_q * sin_r + cos_p * cos_r, sin_p * sin_q * cos_r - cos_p * sin_r},
                {-sin_q, cos_q * sin_r, cos_q * cos_r}
            }
        
            -- 合成回転行列を計算
            local R = {}
            for i = 1, 3 do
                R[i] = {}
                for j = 1, 3 do
                    R[i][j] = 0
                    for k = 1, 3 do
                        R[i][j] = R[i][j] + R1[i][k] * R2[k][j]
                    end
                end
            end
        
            -- 合成回転行列からオイラー角を計算
            local new_a = math.deg(math.atan2(R[2][1], R[1][1]))
            local new_b = math.deg(math.atan2(-R[3][1], math.sqrt(R[3][2] * R[3][2] + R[3][3] * R[3][3])))
            local new_c = math.deg(math.atan2(R[3][2], R[3][3]))
        
            return new_a - a, new_b - b, new_c - c
        end

        local a, b, c = eular_angle.roll, eular_angle.pitch, eular_angle.yaw
        print(a, b, c)
        local p, q, r = 0, 1, 0
        local new_a, new_b, new_c = eulerAngleChange(a, b, c, p, q, r)
        print(new_a, new_b, new_c)
        local vec = Vector3.new(0, 0, 0)
        local angle_vec = Vector3.new(new_b, new_a, new_c)
        print(self.core_obj.vehicle_obj.position_obj.fly_tank_system:AddLinelyVelocity(vec, angle_vec))

        print("Excute Test Function 7")
    end
    ImGui.SameLine()
    if ImGui.Button("TF8") then
        local vec = Vector3.new(0, 0, 0)
        local vec_angle = Vector3.new(0, 0, 0)
        print(self.core_obj.vehicle_obj.position_obj.fly_tank_system:ChangeLinelyVelocity(vec, vec_angle, 1))

        print("Excute Test Function 8")
    end
    ImGui.SameLine()
    if ImGui.Button("TF9") then
        local vec = self.core_obj.vehicle_obj.position_obj.fly_tank_system:GetVelocity()
        print(vec.x , vec.y, vec.z)
        local vec = self.core_obj.vehicle_obj.position_obj.fly_tank_system:GetAngularVelocity()
        print(vec.x , vec.y, vec.z)

        print("Excute Test Function 9")
    end
    ImGui.SameLine()
    if ImGui.Button("TF9-2") then

        print(self.core_obj.vehicle_obj.position_obj.fly_tank_system:GetPhysicsState())

        print("Excute Test Function 9-2")
    end
    ImGui.SameLine()
    if ImGui.Button("TF9-3") then
        local entity = Game.FindEntityByID(self.core_obj.vehicle_obj.entity_id)
        entity:PhysicsWakeUp()
        print(self.core_obj.vehicle_obj.position_obj.fly_tank_system:AddLinelyVelocity(Vector3.new(0, 0, 10), Vector3.new(0, 0, 0)))

        print("Excute Test Function 9-3")
    end
    if ImGui.Button("TF10") then
        self.core_obj.event_obj.hud_obj.hud_tank_controller:TurnOff()
        print("Excute Test Function 10")
    end
    ImGui.SameLine()
    if ImGui.Button("TF11") then
        self.core_obj.event_obj.hud_obj.hud_tank_controller:TurnOn()
        print("Excute Test Function 11")
    end
    ImGui.SameLine()
    if ImGui.Button("TF12") then
        print(self.core_obj.vehicle_obj.position_obj.fly_tank_system:IsOnGround())
        print("Excute Test Function 12")
    end
end


return Debug
