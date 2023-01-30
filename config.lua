dofile("data/scripts/lib/utilities.lua")
dofile("data/scripts/lib/mod_settings.lua")

MOD_ID = "kae_test"

CONF = {
    ENABLE = "enable",  -- should the UI be drawn?
    DEBUG = "debug",    -- is debugging enabled?
    NAV_INPUTS = "nav", -- are nav inputs handled?
}

function conf_get(key)
    return ModSettingGet(MOD_ID .. "." .. key)
end

function conf_set(key, value)
    return ModSettingSetNextValue(MOD_ID .. "." .. key, value, false)
end

-- vim: set ts=4 sts=4 sw=4: