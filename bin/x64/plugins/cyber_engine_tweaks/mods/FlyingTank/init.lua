--------------------------------------------------------
-- CopyRight (C) 2024, tidusmd. All rights reserved.
-- This mod is under the MIT License.
-- https://opensource.org/licenses/mit-license.php
--------------------------------------------------------

Cron = require('External/Cron.lua')
Def = require("Tools/def.lua")
Log = require("Tools/log.lua")

local Core = require('Modules/core.lua')
local Debug = require('Debug/debug.lua')

FlyingTank = {
	description = "Flying Tank - Enhanced Militech Basilisk",
	version = "1.0.0",
    -- system
    is_ready = false,
    time_resolution = 0.01,
    is_debug_mode = false,
    is_opening_overlay = false,
    -- common
    user_setting_path = "Data/user_setting.json",
    language_path = "Language",
    -- grobal index
    model_index = 1,
	model_type_index = 1,
    -- version check
    cet_required_version = 32.1, -- 1.32.1
    cet_recommended_version = 32.2, -- 1.32.2
    codeware_required_version = 8.2, -- 1.8.2
    codeware_recommended_version = 9.2, -- 1.9.2
    native_settings_required_version = 1.96,
    cet_version_num = 0,
    codeware_version_num = 0,
    native_settings_version_num = 0,
    -- setting
    is_valid_native_settings = false,
    NativeSettings = nil,
    -- input
    input_listener = nil,
    listening_keybind_widget = nil,
    default_keybind_table = {
        {name = "move_up", key = "IK_C", pad = "IK_Pad_Y_TRIANGLE"},
        {name = "move_down", key = "IK_Z", pad = "IK_Pad_A_CROSS"},
        {name = "toggle_camera", key = "IK_V", pad = "IK_Pad_DigitDown"},
        {name = "toggle_door", key = "IK_G", pad = "IK_Pad_DigitLeft"},
        {name = "toggle_radio", key = "IK_R", pad = "IK_Pad_DigitUp"},
    }
}

-- initial settings
FlyingTank.user_setting_table = {
    version = FlyingTank.version,
    --- garage
    garage_info_list = {},
    --- free summon mode
    is_free_summon_mode = true,
    model_index_in_free = 1,
    model_type_index_in_free = 1,
    --- autopilot
    mappin_history = {},
    favorite_location_list = {
        {name = "Unselected", pos = {x=0,y=0,z=0}, is_selected = true},
        {name = "Not Registered", pos = {x=0,y=0,z=0}, is_selected = false},
        {name = "Not Registered", pos = {x=0,y=0,z=0}, is_selected = false},
        {name = "Not Registered", pos = {x=0,y=0,z=0}, is_selected = false},
        {name = "Not Registered", pos = {x=0,y=0,z=0}, is_selected = false},
        {name = "Not Registered", pos = {x=0,y=0,z=0}, is_selected = false},
    },
    autopilot_speed_level = Def.AutopilotSpeedLevel.Normal,
    -- is_autopilot_info_panel = true,
    is_enable_history = true,
    --- control
    flight_mode = Def.FlightMode.Spinner,
    heli_horizenal_boost_ratio = 5.0,
    is_disable_spinner_roll_tilt = false,
    --- environment
    is_enable_community_spawn = true,
    max_speed_for_freezing = 150,
    max_spawn_frequency = 20,
    min_spawn_frequency = 10,
    is_mute_all = false,
    is_mute_flight = false,
    --- general
    language_index = 1,
    is_unit_km_per_hour = false,
    --- input
    keybind_table = FlyingTank.default_keybind_table
}

registerForEvent("onOverlayOpen",function ()
	FlyingTank.is_opening_overlay = true
end)

registerForEvent("onOverlayClose",function ()
	FlyingTank.is_opening_overlay = false
end)

-- set custom vehicle record
registerForEvent("onTweak",function ()

    -- Icon
    TweakDB:CloneRecord("UIIcon.basilisk_dummy", "UIIcon.quadra_sport_r7_chiaroscuro")
    TweakDB:SetFlat(TweakDBID.new("UIIcon.basilisk_dummy.atlasResourcePathacturer"), "base/gameplay/gui/common/icons/weapon_manufacturers.inkatlas")
    TweakDB:SetFlat(TweakDBID.new("UIIcon.basilisk_dummy.icon.atlasPartName"), "militech_l")

    -- Vehicle Parameters
    TweakDB:CloneRecord("Vehicle.v_militech_basilisk_inline5_fly", "Vehicle.v_militech_basilisk_inline5")
    TweakDB:SetFlat(TweakDBID.new("Vehicle.v_militech_basilisk_inline5_fly.tankGravityMul"), 0)

    -- Custom Aldecaldos Basilisk Record
    TweakDB:CloneRecord("Vehicle.v_militech_basilisk_fly", "Vehicle.v_militech_basilisk")
    TweakDB:SetFlat(TweakDBID.new("Vehicle.v_militech_basilisk_fly.tankDriveModelData"), "Vehicle.v_militech_basilisk_inline5_fly")

    -- TweakDB:CloneRecord("Vehicle.basilisk_dummy", "Vehicle.v_sport2_quadra_type66_02_player")
    -- TweakDB:SetFlat(TweakDBID.new("Vehicle.basilisk_dummy.displayName"), LocKey(53243))
    -- TweakDB:SetFlat(TweakDBID.new("Vehicle.basilisk_dummy.manufacturer"), "Vehicle.Militech")
    -- TweakDB:SetFlat(TweakDBID.new("Vehicle.basilisk_dummy.icon"), "UIIcon.basilisk_dummy")
    -- TweakDB:SetFlat(TweakDBID.new("Vehicle.basilisk_dummy.dealerAtlasPath"), "base/gameplay/gui/common/icons/codex/assets_fullscreen16.inkatlas")
    -- TweakDB:SetFlat(TweakDBID.new("Vehicle.basilisk_dummy.dealerPartName"), "v_militech_basilisk_full")
    -- TweakDB:SetFlat(TweakDBID.new("Vehicle.basilisk_dummy.dealerPrice"), 1)
    -- TweakDB:SetFlat(TweakDBID.new("Vehicle.basilisk_dummy.dealerCred"), 20)

    -- Custom Militech Basilisk Record
    TweakDB:CloneRecord("Vehicle.v_militech_basilisk_militech_fly", "Vehicle.v_militech_basilisk_militech")
    TweakDB:SetFlat(TweakDBID.new("Vehicle.v_militech_basilisk_militech_fly.tankDriveModelData"), "Vehicle.v_militech_basilisk_inline5_fly")

end)

registerForEvent("onHook", function ()

    -- refer to https://www.nexusmods.com/cyberpunk2077/mods/8326
    FlyingTank.input_listener = NewProxy({
        OnKeyInput = {
            args = {'handle:KeyInputEvent'},
            callback = function(event)
                local key = event:GetKey().value
                local action = event:GetAction().value
                if FlyingTank.listening_keybind_widget and key:find("IK_Pad") and action == "IACT_Release" then -- OnKeyBindingEvent has to be called manually for gamepad inputs, while there is a keybind widget listening for input
                    FlyingTank.listening_keybind_widget:OnKeyBindingEvent(KeyBindingEvent.new({keyName = key}))
                    FlyingTank.listening_keybind_widget = nil
                elseif FlyingTank.listening_keybind_widget and action == "IACT_Release" then -- Key was bound, by keyboard
                    FlyingTank.listening_keybind_widget = nil
                end
                if FlyingTank.core_obj.event_obj.current_situation == Def.Situation.InVehicle then
                    if action == "IACT_Press" then
                        FlyingTank.core_obj:ConvertPressButtonAction(key)
                    elseif action == "IACT_Release" then
                        FlyingTank.core_obj:ConvertReleaseButtonAction(key)
                    end
                end
            end
        }
    })
    Game.GetCallbackSystem():RegisterCallback('Input/Key', FlyingTank.input_listener:Target(), FlyingTank.input_listener:Function("OnKeyInput"), true)
    Observe("SettingsSelectorControllerKeyBinding", "ListenForInput", function(this)
        FlyingTank.listening_keybind_widget = this
    end)

end)

registerForEvent('onInit', function()

    if not FlyingTank:CheckDependencies() then
        print('[Error] Drive an Aerial Vehicle Mod failed to load due to missing dependencies.')
        return
    end

    FlyingTank:CheckNativeSettings()

    FlyingTank.core_obj = Core:New()
    FlyingTank.debug_obj = Debug:New(FlyingTank.core_obj)

    FlyingTank.core_obj:Init()

    FlyingTank.is_ready = true

    print('Drive an Aerial Vehicle Mod is ready!')

end)

registerForEvent("onDraw", function()

    if FlyingTank.is_debug_mode then
        FlyingTank.debug_obj:ImGuiMain()
    end
    if FlyingTank.is_opening_overlay then
        if FlyingTank.core_obj == nil or FlyingTank.core_obj.event_obj == nil or FlyingTank.core_obj.event_obj.ui_obj == nil then
            return
        end
        FlyingTank.core_obj.event_obj.ui_obj:ShowSettingMenu()
    end
    -- FlyingTank.core_obj.event_obj.hud_obj:ShowAutoPilotInfo()

end)

registerForEvent('onUpdate', function(delta)
    Cron.Update(delta)
end)

registerForEvent('onShutdown', function()
    Game.GetCallbackSystem():UnregisterCallback('Input/Key', FlyingTank.input_listener:Target(), FlyingTank.input_listener:Function("OnKeyInput"))
end)

function FlyingTank:CheckDependencies()

    -- Check Cyber Engine Tweaks Version
    local cet_version_str = GetVersion()
    local cet_version_major, cet_version_minor = cet_version_str:match("1.(%d+)%.*(%d*)")
    FlyingTank.cet_version_num = tonumber(cet_version_major .. "." .. cet_version_minor)

    -- Check CodeWare Version
    local code_version_str = Codeware.Version()
    local code_version_major, code_version_minor = code_version_str:match("1.(%d+)%.*(%d*)")
    FlyingTank.codeware_version_num = tonumber(code_version_major .. "." .. code_version_minor)

    if FlyingTank.cet_version_num < FlyingTank.cet_required_version then
        print("Drive an Aerial Vehicle Mod requires Cyber Engine Tweaks version 1." .. FlyingTank.cet_required_version .. " or higher.")
        return false
    elseif FlyingTank.codeware_version_num < FlyingTank.codeware_required_version then
        print("Drive an Aerial Vehicle Mod requires CodeWare version 1." .. FlyingTank.codeware_required_version .. " or higher.")
        return false
    end

    return true

end

function FlyingTank:CheckNativeSettings()

    FlyingTank.NativeSettings = GetMod("nativeSettings")
    if FlyingTank.NativeSettings == nil then
		FlyingTank.is_valid_native_settings = false
        return
	end
    FlyingTank.native_settings_version_num = FlyingTank.NativeSettings.version
    if FlyingTank.NativeSettings.version < FlyingTank.native_settings_required_version then
        FlyingTank.is_valid_native_settings = false
        return
    end
    FlyingTank.is_valid_native_settings = true
    return

end

function FlyingTank:Version()
    return FlyingTank.version
end

return FlyingTank