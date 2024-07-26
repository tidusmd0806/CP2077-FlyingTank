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
	obj.vehicle_obj = nil
	-- native settings page
	obj.dummy_basilisk_aldecaldos_record_id = nil
	obj.dummy_basilisk_militech_record_id = nil
	obj.option_table_list = {}
    return setmetatable(obj, self)
end

function UI:Init(vehicle_obj)
	self.vehicle_obj = vehicle_obj
	self:CreateNativeSettingsBasePage()
end

function UI:CreateNativeSettingsBasePage()
	FlyingTank.NativeSettings.addTab("/FlyingTank", FlyingTank.core_obj:GetTranslationText("native_settings_keybinds_title"))
	FlyingTank.NativeSettings.addSubcategory("/FlyingTank/activation", FlyingTank.core_obj:GetTranslationText("native_settings_activation_subtitle"))
	FlyingTank.NativeSettings.addSubcategory("/FlyingTank/keybinds", FlyingTank.core_obj:GetTranslationText("native_settings_keybinds_subtitle"))
	FlyingTank.NativeSettings.addSubcategory("/FlyingTank/controller", FlyingTank.core_obj:GetTranslationText("native_settings_controller_subtitle"))
	FlyingTank.NativeSettings.addSubcategory("/FlyingTank/general", FlyingTank.core_obj:GetTranslationText("native_settings_general_subtitle"))
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
	option_table = FlyingTank.NativeSettings.addSwitch("/FlyingTank/activation", FlyingTank.core_obj:GetTranslationText("native_settings_activation_tank"), FlyingTank.core_obj:GetTranslationText("native_settings_activation_tank_description"), FlyingTank.user_setting_table.is_activate_vehicle_switch, false, function(state)
		FlyingTank.user_setting_table.is_activate_vehicle_switch = state
		Utils:WriteJson(FlyingTank.user_setting_path, FlyingTank.user_setting_table)
		Cron.After(self.delay_updating_native_settings, function()
			self:UpdateNativeSettingsPage()
		end)
	end)
	table.insert(self.option_table_list, option_table)
	if FlyingTank.user_setting_table.is_activate_vehicle_switch then
		local is_aldecaldos_tank = Game.GetVehicleSystem():IsVehiclePlayerUnlocked(TweakDBID.new(FlyingTank.basilisk_aldecaldos_record))
		local is_militech_tank = Game.GetVehicleSystem():IsVehiclePlayerUnlocked(TweakDBID.new(FlyingTank.basilisk_militech_record))
		option_table = FlyingTank.NativeSettings.addSwitch("/FlyingTank/activation", FlyingTank.core_obj:GetTranslationText("native_settings_activation_aldecaldos"), FlyingTank.core_obj:GetTranslationText("native_settings_activation_aldecaldos_description"), is_aldecaldos_tank, is_aldecaldos_tank, function(state)
			Game.GetVehicleSystem():EnablePlayerVehicle(FlyingTank.basilisk_aldecaldos_record, state, true)
			Cron.After(self.delay_updating_native_settings, function()
				self:UpdateNativeSettingsPage()
			end)
		end)
		table.insert(self.option_table_list, option_table)
		option_table = FlyingTank.NativeSettings.addSwitch("/FlyingTank/activation", FlyingTank.core_obj:GetTranslationText("native_settings_activation_militech"), FlyingTank.core_obj:GetTranslationText("native_settings_activation_militech_description"), is_militech_tank, is_militech_tank, function(state)
			Game.GetVehicleSystem():EnablePlayerVehicle(FlyingTank.basilisk_militech_record, state, true)
			Cron.After(self.delay_updating_native_settings, function()
				self:UpdateNativeSettingsPage()
			end)
		end)
		table.insert(self.option_table_list, option_table)
	end
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