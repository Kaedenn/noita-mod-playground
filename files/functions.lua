dofile_once("data/scripts/lib/utilities.lua")

function asboolean(value)
    if type(value) == "boolean" then return value end
    if type(value) == "number" then return value ~= 0 end
    if type(value) == "string" then
        if value == "1" or value == "true" then return true end
        if value == "0" or value == "false" then return false end
    end
    return nil
end

function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

function value_interpret(value, astype)
    if astype == nil then
        return tostring(value)
    elseif astype == "string" then
        if type(value) == "boolean" then
            if value then
                return "1"
            end
            return "0"
        elseif type(value) ~= "string" then
            return ("%s"):format(value)
        else
            return value
        end
    elseif astype == "boolean" then
        if type(value) == "string" then
            return value == "1"
        elseif type(value) == "number" then
            return value == 1
        elseif type(value) ~= "boolean" then
            return ("%s"):format(value) == "1"
        elseif value then
            return true
        end
        return false
    end
end

function mkfn_setting_get(setting)
    return function()
        return GameSettingGet(setting)
    end
end

function mkfn_setting_set(setting, astype)
    return function(value)
        local value_final = value_interpret(value, astype)
        GameSettingSet(setting, value_final)
    end
end



-- vim: set ts=4 sts=4 sw=4:
