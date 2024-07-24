local Utils = require("Tools/utils.lua")
local UI = {}
UI.__index = UI

function UI:New()
	-- instance --
    local obj = {}
    obj.log_obj = Log:New()
    obj.log_obj:SetLevel(LogLevel.Info, "UI")
	-- static --
	-- native settings
	obj.delay_updating_native_settings = 0.1
	-- dynamic --
	-- common
	obj.vehicle_obj = nil
	obj.dummy_basilisk_aldecaldos_record_id = nil
	obj.dummy_basilisk_militech_record_id = nil
	obj.av_record_list = {}
	-- garage
	obj.selected_purchased_vehicle_type_list = {}
    -- free summon
    obj.vehicle_model_list = {}
	obj.selected_vehicle_model_name = ""
    obj.selected_vehicle_model_number = 1
	obj.vehicle_type_list = {}
	obj.selected_vehicle_type_name = ""
	obj.selected_vehicle_type_number = 1
	obj.current_vehicle_model_name = ""
	obj.current_vehicle_type_name = ""
	obj.temp_vehicle_model_name = ""
	-- auto pilot setting
	obj.selected_auto_pilot_history_index = 1
	obj.selected_auto_pilot_history_name = ""
	obj.history_list = {}
	obj.current_position_name = ""
	-- control setting
	obj.selected_flight_mode = Def.FlightMode.Heli
	obj.max_boost_ratio = 15.0
	-- enviroment setting
	obj.max_spawn_frequency_max = 100
	obj.max_spawn_frequency_min = 20
	obj.min_spawn_frequency_max = 15
	obj.min_spawn_frequency_min = 5
	-- general setting
	obj.selected_language_name = ""
	-- info
	obj.dummy_check_1 = false
	obj.dummy_check_2 = false
	obj.dummy_check_3 = false
	obj.dummy_check_4 = false
	obj.dummy_check_5 = false

	-- native settings page
	obj.option_table_list = {}
    return setmetatable(obj, self)
end

function UI:Init(vehicle_obj)
	self.vehicle_obj = vehicle_obj
	self:SetTweekDB()
	self:SetDefaultValue()
	self:CreateNativeSettingsBasePage()
end

function UI:SetTweekDB()

    self.dummy_basilisk_aldecaldos_record_id = TweakDBID.new(FlyingTank.basilisk_aldecaldos_record)
	self.dummy_basilisk_militech_record_id = TweakDBID.new(FlyingTank.basilisk_militech_record)

	for _, model in ipairs(self.vehicle_obj.all_models) do
		local av_record = TweakDBID.new(model.tweakdb_id)
		table.insert(self.av_record_list, av_record)
	end

end

function UI:SetDefaultValue()

	self.selected_purchased_vehicle_type_list = {}
	-- garage
	for _, garage_info in ipairs(FlyingTank.user_setting_table.garage_info_list) do
		table.insert(self.selected_purchased_vehicle_type_list, self.vehicle_obj.all_models[garage_info.model_index].type[garage_info.type_index])
	end

	--free summon mode
	-- for i, model in ipairs(self.vehicle_obj.all_models) do
    --     self.vehicle_model_list[i] = model.name
	-- end
	-- self.selected_vehicle_model_number = FlyingTank.user_setting_table.model_index_in_free
	-- self.selected_vehicle_model_name = self.vehicle_model_list[self.selected_vehicle_model_number]

	-- for i, type in ipairs(self.vehicle_obj.all_models[self.selected_vehicle_model_number].type) do
	-- 	self.vehicle_type_list[i] = type
	-- end
	-- self.selected_vehicle_type_number = FlyingTank.user_setting_table.model_type_index_in_free
	-- self.selected_vehicle_type_name = self.vehicle_type_list[self.selected_vehicle_type_number]

	-- self.current_vehicle_model_name = self.vehicle_model_list[self.selected_vehicle_model_number]
	-- self.current_vehicle_type_name = self.vehicle_type_list[self.selected_vehicle_type_number]

	-- auto pilot setting
	-- self:CreateStringHistory()
	-- self.selected_auto_pilot_history_index = 1
	-- self.selected_auto_pilot_history_name = self.history_list[self.selected_auto_pilot_history_index]
	-- for index, favorite_info in ipairs(FlyingTank.user_setting_table.favorite_location_list) do
	-- 	if favorite_info.is_selected then
	-- 		self.selected_auto_pilot_favorite_index = index
	-- 		break
	-- 	end
	-- end
	-- FlyingTank.core_obj:SetFavoriteMappin(FlyingTank.user_setting_table.favorite_location_list[self.selected_auto_pilot_favorite_index].pos)

	-- control
	self.selected_flight_mode = FlyingTank.user_setting_table.flight_mode

	-- general
	self.selected_language_name = FlyingTank.core_obj.language_name_list[FlyingTank.user_setting_table.language_index]

	-- info
	self.dummy_check_1 = false
	self.dummy_check_2 = false
	self.dummy_check_3 = false
	self.dummy_check_4 = false
	self.dummy_check_5 = false

end

function UI:SetMenuColor()
	ImGui.PushStyleColor(ImGuiCol.TitleBg, 0, 0.5, 0, 0.5)
	ImGui.PushStyleColor(ImGuiCol.TitleBgCollapsed, 0, 0.5, 0, 0.5)
	ImGui.PushStyleColor(ImGuiCol.TitleBgActive, 0, 0.5, 0, 0.5)
	ImGui.PushStyleColor(ImGuiCol.WindowBg, 0, 0, 0, 0.7)
	ImGui.PushStyleColor(ImGuiCol.Tab, 0, 0.5, 0, 0.7)
	ImGui.PushStyleColor(ImGuiCol.TabHovered, 0.5, 0.5, 0.5, 0.5)
	ImGui.PushStyleColor(ImGuiCol.TabActive, 0, 0, 0.8, 0.7)
	ImGui.PushStyleColor(ImGuiCol.Button, 0, 0.7, 0, 0.7)
	ImGui.PushStyleColor(ImGuiCol.ButtonHovered, 0.5, 0.5, 0.5, 0.5)
	ImGui.PushStyleColor(ImGuiCol.ButtonActive, 0, 0.7, 0, 0.7)
	ImGui.PushStyleColor(ImGuiCol.FrameBg, 0.5, 0.5, 0.5, 0.7)
	ImGui.PushStyleColor(ImGuiCol.FrameBgHovered, 0.5, 0.5, 0.5, 0.5)
	ImGui.PushStyleColor(ImGuiCol.FrameBgActive, 0.5, 0.5, 0.5, 0.7)
	ImGui.PushStyleColor(ImGuiCol.CheckMark, 0, 0.7, 0, 0.8)
end

function UI:ShowSettingMenu()

	self:SetMenuColor()
    ImGui.Begin("FlyingTank Menu")

	if ImGui.BeginTabBar("FlyingTank Menu") then

		-- if ImGui.BeginTabItem(FlyingTank.core_obj:GetTranslationText("ui_tab_garage")) then
		-- 	self:ShowGarage()
		-- 	ImGui.EndTabItem()
		-- end

		if ImGui.BeginTabItem(FlyingTank.core_obj:GetTranslationText("ui_tab_free_summon")) then
			self:ShowFreeSummon()
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem(FlyingTank.core_obj:GetTranslationText("ui_tab_control_setting")) then
			self:ShowControlSetting()
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem(FlyingTank.core_obj:GetTranslationText("ui_tab_environment_setting")) then
			self:ShowEnviromentSetting()
			ImGui.EndTabItem()
		end

		if ImGui.BeginTabItem(FlyingTank.core_obj:GetTranslationText("ui_tab_info")) then
			self:ShowInfo()
			ImGui.EndTabItem()
		end

		ImGui.EndTabBar()

	end

    ImGui.End()

end

function UI:ShowGarage()

	local selected = false

	ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_garage_title"))

	ImGui.Separator()

	for model_index, garage_info in ipairs(FlyingTank.user_setting_table.garage_info_list) do
		ImGui.Text(self.vehicle_obj.all_models[garage_info.model_index].name)
		ImGui.SameLine()
		ImGui.Text(" : ")
		ImGui.SameLine()
		if garage_info.is_purchased then
			ImGui.TextColored(0, 1, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_garage_purchased"))
		else
			ImGui.TextColored(1, 0, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_garage_not_purchased"))
		end

		if ImGui.BeginCombo("##" .. self.vehicle_obj.all_models[garage_info.model_index].name, self.selected_purchased_vehicle_type_list[model_index]) then
			for index, value in ipairs(self.vehicle_obj.all_models[garage_info.model_index].type) do
				if self.selected_purchased_vehicle_type_list[model_index] == value.name then
					selected = true
				else
					selected = false
				end
				if(ImGui.Selectable(value, selected)) then
					self.selected_purchased_vehicle_type_list[model_index] = value
					FlyingTank.core_obj:ChangeGarageAVType(garage_info.name, index)
				end
			end
			ImGui.EndCombo()
		end

		ImGui.Separator()
	end

end

function UI:ShowFreeSummon()

	local temp_is_free_summon_mode = FlyingTank.user_setting_table.is_free_summon_mode
	local selected = false

	FlyingTank.user_setting_table.is_free_summon_mode = ImGui.Checkbox(FlyingTank.core_obj:GetTranslationText("ui_free_summon_enable_summon"), FlyingTank.user_setting_table.is_free_summon_mode)
	if temp_is_free_summon_mode ~= FlyingTank.user_setting_table.is_free_summon_mode then
		Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
	end

	ImGui.Separator()
	ImGui.Spacing()

	if not FlyingTank.user_setting_table.is_free_summon_mode then
		ImGui.TextColored(1, 1, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_free_summon_warning_message_in_summoning_1"))
		ImGui.TextColored(1, 1, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_free_summon_warning_message_in_summoning_3"))
		return
	end

	ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_free_summon_select_model"))
	ImGui.SameLine()
	ImGui.TextColored(0, 1, 0, 1, self.current_vehicle_model_name)
	ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_free_summon_select_type"))
	ImGui.SameLine()
	ImGui.TextColored(0, 1, 0, 1, self.current_vehicle_type_name)

	ImGui.Separator()
	ImGui.Spacing()

	if not FlyingTank.core_obj.event_obj:IsNotSpawned() then
		ImGui.TextColored(1, 0, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_free_summon_warning_message_in_summoning_1"))
		ImGui.TextColored(1, 0, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_free_summon_warning_message_in_summoning_2"))
		return
	end

	if self.selected_vehicle_model_name == nil then
		self.selected_vehicle_model_name = self.vehicle_model_list[1]
		return
	end
	if self.selected_vehicle_model_number == nil then
		self.selected_vehicle_model_number = 1
		return
	end

	ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_free_summon_select_model_explain"))
	if ImGui.BeginCombo("##AV Model", self.selected_vehicle_model_name) then
		for index, value in ipairs(self.vehicle_model_list) do
			if self.selected_vehicle_model_name == value.name then
				selected = true
			else
				selected = false
			end
			if(ImGui.Selectable(value, selected)) then
				self.selected_vehicle_model_name = value
				self.selected_vehicle_model_number = index
			end
		end
		ImGui.EndCombo()
	end

	if self.current_vehicle_model_name ~= self.selected_vehicle_model_name and self.selected_vehicle_model_name ~= self.temp_vehicle_model_name then
		self.temp_vehicle_model_name = self.selected_vehicle_model_name
		self.selected_vehicle_type_number = 1
	end

	self.vehicle_type_list = {}

	for i, type in ipairs(self.vehicle_obj.all_models[self.selected_vehicle_model_number].type) do
		self.vehicle_type_list[i] = type
	end

	self.selected_vehicle_type_name = self.vehicle_type_list[self.selected_vehicle_type_number]

	if self.selected_vehicle_type_name == nil then
		self.selected_vehicle_type_name = self.vehicle_type_list[1]
		return
	end
	if self.selected_vehicle_type_number == nil then
		self.selected_vehicle_type_number = 1
		return
	end

	ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_free_summon_select_model_explain"))
	if ImGui.BeginCombo("##AV Type", self.selected_vehicle_type_name) then
		for index, value in ipairs(self.vehicle_type_list) do
			if self.selected_vehicle_type_name == value then
				selected = true
			else
				selected = false
			end
			if(ImGui.Selectable(value, selected)) then
				self.selected_vehicle_type_name = value
				self.selected_vehicle_type_number = index
			end
		end
		ImGui.EndCombo()
	end

	-- if FlyingTank.user_setting_table.model_index_in_free ~= self.selected_vehicle_model_number or FlyingTank.user_setting_table.model_type_index_in_free ~= self.selected_vehicle_type_number then
	-- 	self:SetFreeSummonParameters()
	-- end

end

function UI:ShowControlSetting()

	if not FlyingTank.core_obj.event_obj:IsNotSpawned() then
		ImGui.TextColored(1, 0, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_free_summon_warning_message_in_summoning_1"))
		ImGui.TextColored(1, 0, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_free_summon_warning_message_in_summoning_2"))
		return
	end

	local selected = false
	ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_control_setting_select_flight_mode"))
	if ImGui.BeginCombo("##Flight Mode", self.selected_flight_mode) then
		for _, value in pairs(Def.FlightMode) do
			if self.selected_flight_mode == value then
				selected = true
			else
				selected = false
			end
			if(ImGui.Selectable(value, selected)) then
				self.selected_flight_mode = value
				FlyingTank.user_setting_table.flight_mode = value
				Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
			end
		end
		ImGui.EndCombo()
	end

	ImGui.Spacing()

	ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_control_setting_explain_spinner"))
	ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_control_setting_explain_Heli"))

	ImGui.Separator()
	ImGui.Spacing()

	local is_disable_spinner_roll_tilt = FlyingTank.user_setting_table.is_disable_spinner_roll_tilt
	if FlyingTank.user_setting_table.flight_mode == Def.FlightMode.Heli then
		ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_control_setting_horizenal_boost"))
		local is_used_slider = false
		local heli_horizenal_boost_ratio = FlyingTank.user_setting_table.heli_horizenal_boost_ratio
		FlyingTank.user_setting_table.heli_horizenal_boost_ratio, is_used_slider = ImGui.SliderFloat("##Horizenal Boost Ratio", FlyingTank.user_setting_table.heli_horizenal_boost_ratio, 1.0, self.max_boost_ratio, "%.1f")
		if not is_used_slider and FlyingTank.user_setting_table.heli_horizenal_boost_ratio ~= heli_horizenal_boost_ratio then
			Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
		end
	elseif FlyingTank.user_setting_table.flight_mode == Def.FlightMode.Spinner then
		FlyingTank.user_setting_table.is_disable_spinner_roll_tilt = ImGui.Checkbox(FlyingTank.core_obj:GetTranslationText("ui_control_setting_disable_left_right"), FlyingTank.user_setting_table.is_disable_spinner_roll_tilt)
		if is_disable_spinner_roll_tilt ~= FlyingTank.user_setting_table.is_disable_spinner_roll_tilt then
			Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
		end
	end

end

function UI:ShowEnviromentSetting()

	ImGui.TextColored(0.8, 0.8, 0.5, 1, FlyingTank.core_obj:GetTranslationText("ui_environment_setting_community_spawn"))

	if not FlyingTank.core_obj.event_obj:IsNotSpawned() then
		ImGui.TextColored(1, 0, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_free_summon_warning_message_in_summoning_1"))
		ImGui.TextColored(1, 0, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_free_summon_warning_message_in_summoning_2"))
	else
		local is_enable_community_spawn = FlyingTank.user_setting_table.is_enable_community_spawn
		FlyingTank.user_setting_table.is_enable_community_spawn = ImGui.Checkbox(FlyingTank.core_obj:GetTranslationText("ui_environment_enable_community_spawn"), FlyingTank.user_setting_table.is_enable_community_spawn)
		if FlyingTank.user_setting_table.is_enable_community_spawn ~= is_enable_community_spawn then
			Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
		end
		ImGui.TextColored(1, 0, 0, 1, FlyingTank.core_obj:GetTranslationText("ui_environment_warning_message_about_community_spawn"))
		if FlyingTank.user_setting_table.is_enable_community_spawn then
			ImGui.TextColored(0.8, 0.8, 0.5, 1, FlyingTank.core_obj:GetTranslationText("ui_environment_advanced_setting"))
			ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_environment_limit_spawn_speed"))
			local is_used_slider = false
			local max_speed_for_freezing = FlyingTank.user_setting_table.max_speed_for_freezing
			FlyingTank.user_setting_table.max_speed_for_freezing, is_used_slider = ImGui.SliderInt("##max spawn speed", FlyingTank.user_setting_table.max_speed_for_freezing, 0, 400, "%d")
			if not is_used_slider and FlyingTank.user_setting_table.max_speed_for_freezing ~= max_speed_for_freezing then
				self.vehicle_obj.max_speed_for_freezing = FlyingTank.user_setting_table.max_speed_for_freezing
				Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
			end
			ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_environment_maximum_update_interval"))
			local max_spawn_frequency = FlyingTank.user_setting_table.max_spawn_frequency
			local min_spawn_frequency = FlyingTank.user_setting_table.min_spawn_frequency
			FlyingTank.user_setting_table.max_spawn_frequency, is_used_slider = ImGui.SliderInt("##max spawn frequency", FlyingTank.user_setting_table.max_spawn_frequency, min_spawn_frequency + 1, self.max_spawn_frequency_max, "%d")
			if not is_used_slider and FlyingTank.user_setting_table.max_spawn_frequency ~= max_spawn_frequency then
				self.vehicle_obj.max_freeze_count = FlyingTank.user_setting_table.max_spawn_frequency
				Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
			end
			ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_environment_minimum_update_interval"))
			FlyingTank.user_setting_table.min_spawn_frequency, is_used_slider = ImGui.SliderInt("##min spawn frequency", FlyingTank.user_setting_table.min_spawn_frequency, self.min_spawn_frequency_min, max_spawn_frequency - 1, "%d")
			if not is_used_slider and FlyingTank.user_setting_table.min_spawn_frequency ~= min_spawn_frequency then
				self.vehicle_obj.min_freeze_count = FlyingTank.user_setting_table.min_spawn_frequency
				Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
			end
		end

	end

	ImGui.Spacing()
	ImGui.Separator()

	ImGui.TextColored(0.8, 0.8, 0.5, 1, FlyingTank.core_obj:GetTranslationText("ui_environment_setting_Sound_title"))
	local is_mute_all = FlyingTank.user_setting_table.is_mute_all
	FlyingTank.user_setting_table.is_mute_all = ImGui.Checkbox(FlyingTank.core_obj:GetTranslationText("ui_environment_setting_mute_all"), FlyingTank.user_setting_table.is_mute_all)
	if FlyingTank.user_setting_table.is_mute_all ~= is_mute_all then
		Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
	end
	local is_mute_flight = FlyingTank.user_setting_table.is_mute_flight
	FlyingTank.user_setting_table.is_mute_flight = ImGui.Checkbox(FlyingTank.core_obj:GetTranslationText("ui_environment_setting_mute_flight"), FlyingTank.user_setting_table.is_mute_flight)
	if FlyingTank.user_setting_table.is_mute_flight ~= is_mute_flight then
		Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
	end

end

function UI:ShowInfo()
	ImGui.Text("Drive an Aerial Vehicle Version: " .. FlyingTank.version)
	if FlyingTank.cet_version_num < FlyingTank.cet_recommended_version then
		ImGui.TextColored(1, 0, 0, 1, "CET Version: " .. GetVersion() .. "(Not Recommended Version)")
	else
		ImGui.Text("CET Version: " .. GetVersion())
	end
	if FlyingTank.codeware_version_num < FlyingTank.codeware_recommended_version then
		ImGui.TextColored(1, 0, 0, 1, "Codeware Version: " .. Codeware.Version() .. "(Not Recommended Version)")
	else
		ImGui.Text("CodeWare Version: " .. Codeware.Version())
	end
	if FlyingTank.native_settings_version_num < FlyingTank.native_settings_required_version then
		ImGui.TextColored(1, 0, 0, 1, "Native Settings may not be installed or may be outdated.")
	else
		ImGui.Text("Native Settings Version: " .. FlyingTank.native_settings_version_num)
	end

	ImGui.Spacing()
	ImGui.Separator()

	ImGui.Text(FlyingTank.core_obj:GetTranslationText("ui_setting_reset_setting"))
	if ImGui.Button(FlyingTank.core_obj:GetTranslationText("ui_setting_reset_setting_button")) then
		FlyingTank.core_obj:ResetSetting()
	end

	ImGui.Spacing()
	ImGui.Separator()

	ImGui.Text("Debug Checkbox (Developer Mode)")
	self.dummy_check_1 = ImGui.Checkbox("1", self.dummy_check_1)
	ImGui.SameLine()
	self.dummy_check_2 = ImGui.Checkbox("2", self.dummy_check_2)
	ImGui.SameLine()
	self.dummy_check_3 = ImGui.Checkbox("3", self.dummy_check_3)
	ImGui.SameLine()
	self.dummy_check_4 = ImGui.Checkbox("4", self.dummy_check_4)
	ImGui.SameLine()
	self.dummy_check_5 = ImGui.Checkbox("5", self.dummy_check_5)

	if not self.dummy_check_1 and self.dummy_check_2 and not self.dummy_check_3 and not self.dummy_check_4 and self.dummy_check_5 then
		FlyingTank.is_debug_mode = true
	else
		FlyingTank.is_debug_mode = false
	end
end

function UI:SetFreeSummonParameters()

	-- FlyingTank.user_setting_table.model_index_in_free = self.selected_vehicle_model_number
	-- FlyingTank.user_setting_table.model_type_index_in_free = self.selected_vehicle_type_number
	FlyingTank.core_obj:Reset()

	self.current_vehicle_model_name = self.vehicle_model_list[self.selected_vehicle_model_number]
	self.current_vehicle_type_name = self.vehicle_type_list[self.selected_vehicle_type_number]

	Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)

end

function UI:CreateStringHistory()
	self.history_list = {}
	for index, history in ipairs(FlyingTank.user_setting_table.mappin_history) do
		local history_string = tostring(index) .. ": "
		for _, district in ipairs(history.district) do
			history_string = history_string .. district .. "/"
		end
		history_string = history_string .. history.location
		history_string = history_string .. " [" .. tostring(math.floor(history.distance)) .. "m]"
		table.insert(self.history_list, history_string)
	end
end

function UI:CreateNativeSettingsBasePage()
	FlyingTank.NativeSettings.addTab("/FlyingTank", FlyingTank.core_obj:GetTranslationText("native_settings_keybinds_title"))
	FlyingTank.NativeSettings.addSubcategory("/FlyingTank/general", FlyingTank.core_obj:GetTranslationText("native_settings_general_subtitle"))
	FlyingTank.NativeSettings.addSubcategory("/FlyingTank/keybinds", FlyingTank.core_obj:GetTranslationText("native_settings_keybinds_subtitle"))
	FlyingTank.NativeSettings.addSubcategory("/FlyingTank/controller", FlyingTank.core_obj:GetTranslationText("native_settings_controller_subtitle"))
	self:CreateNativeSettingsPage()
end

function UI:CreateNativeSettingsPage()

	if not FlyingTank.is_valid_native_settings then
		return
	end
	self.option_table_list = {}
	local option_table

    option_table = FlyingTank.NativeSettings.addSelectorString("/FlyingTank/general", FlyingTank.core_obj:GetTranslationText("native_settings_general_language"), FlyingTank.core_obj:GetTranslationText("native_settings_general_language_description"), FlyingTank.core_obj.language_name_list, FlyingTank.user_setting_table.language_index, 1, function(index)
		FlyingTank.user_setting_table.language_index = index
		Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
		Cron.After(self.delay_updating_native_settings, function()
			self:UpdateNativeSettingsPage()
		end)
	end)
	table.insert(self.option_table_list, option_table)
	-- option_table = FlyingTank.NativeSettings.addSwitch("/FlyingTank/general", FlyingTank.core_obj:GetTranslationText("native_settings_general_unit"), FlyingTank.core_obj:GetTranslationText("native_settings_general_unit_description"), FlyingTank.user_setting_table.is_unit_km_per_hour, false, function(state)
	-- 	FlyingTank.user_setting_table.is_unit_km_per_hour = state
	-- 	Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
	-- 	Cron.After(self.delay_updating_native_settings, function()
	-- 		self:UpdateNativeSettingsPage()
	-- 	end)
	-- end)
	table.insert(self.option_table_list, option_table)
	for index, keybind_list in ipairs(FlyingTank.user_setting_table.keybind_table) do
		option_table = FlyingTank.NativeSettings.addKeyBinding("/FlyingTank/keybinds", FlyingTank.core_obj:GetTranslationText("native_settings_keybinds_" .. keybind_list.name), FlyingTank.core_obj:GetTranslationText("native_settings_keybinds_" .. keybind_list.name .. "_description"), keybind_list.key, FlyingTank.default_keybind_table[index].key, false, function(key)
			if string.find(key, "IK_Pad") then
				self.log_obj:Record(LogLevel.Warning, "Invalid keybind (no keyboard): " .. key)
			else
				FlyingTank.user_setting_table.keybind_table[index].key = key
				Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
			end
			Cron.After(self.delay_updating_native_settings, function()
				self:UpdateNativeSettingsPage()
			end)
		end)
		table.insert(self.option_table_list, option_table)
	end
	for index, keybind_list in ipairs(FlyingTank.user_setting_table.keybind_table) do
		option_table = FlyingTank.NativeSettings.addKeyBinding("/FlyingTank/controller", FlyingTank.core_obj:GetTranslationText("native_settings_keybinds_" .. keybind_list.name), FlyingTank.core_obj:GetTranslationText("native_settings_keybinds_" .. keybind_list.name .. "_description"), keybind_list.pad, FlyingTank.default_keybind_table[index].pad, false, function(pad)
			if not string.find(pad, "IK_Pad") then
				self.log_obj:Record(LogLevel.Warning, "Invalid keybind (no controller): " .. pad)
			else
				FlyingTank.user_setting_table.keybind_table[index].pad = pad
				Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
			end
			Cron.After(self.delay_updating_native_settings, function()
				self:UpdateNativeSettingsPage()
			end)
		end)
		table.insert(self.option_table_list, option_table)
	end

end

function UI:ClearNativeSettingsPage()

	if not FlyingTank.is_valid_native_settings then
		return
	end
	for _, option_table in ipairs(self.option_table_list) do
		FlyingTank.NativeSettings.removeOption(option_table)
	end
	self.option_table_list = {}

end

function UI:UpdateNativeSettingsPage()
	self:ClearNativeSettingsPage()
	self:CreateNativeSettingsPage()
end

return UI