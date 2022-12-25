dofile("data/scripts/lib/utilities.lua")
dofile("data/scripts/lib/mod_settings.lua")

-- Available functions:
-- ModSettingSetNextValue(setting_id, next_value, true/false)
-- ModSettingSet(setting_id, new_value)

function mod_setting_changed_callback(mod_id, gui, in_main_menu, setting, old_value, new_value)
end

local mod_id = "kae_test"
mod_settings_version = 1
mod_settings = {
    {
        id = "enable",
        ui_name = "Enable UI",
        ui_description = "Uncheck this to hide the UI",
        value_default = true,
        scope = MOD_SETTING_SCOPE_RUNTIME,
    },
}

function ModSettingsUpdate(init_scope)
    local old_version = mod_settings_get_version(mod_id)
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end

-- vim: set ts=4 sts=4 sw=4:
