local Utils = require("Tools/utils.lua")
local Debug = {}
Debug.__index = Debug

function Debug:New(core_obj)
    local obj = {}
    obj.core_obj = core_obj

    -- set parameters
    obj.is_set_observer = false
    obj.is_im_gui_rw_count = false
    obj.is_im_gui_vehicle_info = false
    obj.is_im_gui_situation = false
    obj.is_im_gui_player_position = false
    obj.is_im_gui_av_position = false
    obj.is_im_gui_heli_info = false
    obj.is_im_gui_spinner_info = false
    obj.is_im_gui_engine_info = false
    obj.is_im_gui_sound_check = false
    obj.selected_sound = "100_call_vehicle"
    obj.is_im_gui_radio_info = false
    obj.is_im_gui_measurement = false

    return setmetatable(obj, self)
end

function Debug:ImGuiMain()

    ImGui.Begin("FlyingTank DEBUG WINDOW")
    ImGui.Text("Debug Mode : On")

    self:SetObserver()
    self:SetLogLevel()
    self:SelectPrintDebug()
    self:ImGuiShowRWCount()
    self:ImGuiVehicleInfo()
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

function Debug:ImGuiVehicleInfo()
    self.is_im_gui_vehicle_info = ImGui.Checkbox("[ImGui] Vehicle Info", self.is_im_gui_vehicle_info)
    if self.is_im_gui_vehicle_info then
        if self.core_obj.vehicle_obj == nil then
            return
        end
        local left_door_state = self.core_obj.vehicle_obj:GetDoorState(EVehicleDoor.seat_front_left)
        ImGui.Text("Door State : " .. tostring(left_door_state) )
        if self.core_obj.vehicle_obj.position_obj.fly_tank_system == nil then
            return
        end
        if self.core_obj.vehicle_obj.position_obj.fly_tank_system:IsOnGround() then
            ImGui.Text("On Ground")
        else
            ImGui.Text("In Air")
        end
        ImGui.Text("Phy State: " .. tostring(self.core_obj.vehicle_obj.position_obj.fly_tank_system:GetPhysicsState()))
        if self.core_obj.vehicle_obj.position_obj.fly_tank_system:HasGravity() then
            ImGui.Text("Gravity : On")
        else
            ImGui.Text("Gravity : Off")
        end
        local speed = self.core_obj.vehicle_obj.position_obj.fly_tank_system:GetVelocity()
        local speed_x = string.format("%.2f", speed.x)
        local speed_y = string.format("%.2f", speed.y)
        local speed_z = string.format("%.2f", speed.z)
        ImGui.Text("Speed : X:" .. speed_x .. ", Y:" .. speed_y .. ", Z:" .. speed_z)
        local force = self.core_obj.vehicle_obj.position_obj.fly_tank_system:GetForce()
        local force_x = string.format("%.2f", force.x)
        local force_y = string.format("%.2f", force.y)
        local force_z = string.format("%.2f", force.z)
        ImGui.Text("Force : X:" .. force_x .. ", Y:" .. force_y .. ", Z:" .. force_z)

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
        local sys = self.core_obj.vehicle_obj.position_obj.fly_tank_system
        sys:AddForce(Vector3.new(0, 0, 1000000), Vector3.new(0, 0, 0))
        print("Excute Test Function 1")
    end
    ImGui.SameLine()
    if ImGui.Button("TF2") then
        local sys = self.core_obj.vehicle_obj.position_obj.fly_tank_system
        sys:UnsetPhysicsState()
        print("Excute Test Function 2")
    end
end


return Debug
