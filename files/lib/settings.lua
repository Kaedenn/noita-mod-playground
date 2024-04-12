--[[ Persistent storage through mod settings ]]

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")

function setting_init(mod_id)
    local this = {}
    setmetatable(this, {
        __index = function(tbl, key)
            local varname = mod_id .. "." .. key
            return ModSettingGetNextValue(varname)
        end,

        __newindex = function(tbl, key, value)
            local varname = mod_id .. "." .. key
            ModSettingSetNextValue(varname, value, false)
        end
    })
    return this
end

-- vim: set ts=4 sts=4 sw=4:
