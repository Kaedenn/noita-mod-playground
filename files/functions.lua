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

--[[ table_without(tbl, key) -> tbl, boolean
--
-- If the given key is present in the table, then this function returns
-- a copy of the input table without the specified key. Otherwise, the
-- input table is returned as-is. Also returns a boolean indicating
-- whether or not the value was actually removed.
--
-- This function works as expected even if tbl[key] is nil.
--
-- No modifications are made to the input table.
--]]
function table_without(tbl, key)
    local tcopy = {}
    local result = false
    for tkey, tvalue in pairs(tbl) do
        if tkey == key then
            result = true
        else
            tcopy[tkey] = tvalue
        end
    end
    if result then return tcopy, true end
    return tbl, false
end

--[[ table_has(tbl, key) -> boolean
--
-- Returns true if the table contains the given key, false otherwise.
-- Works as expected even if the key or tbl[key] are nil.
--]]
function table_has(tbl, key)
    for tkey, _ in pairs(tbl) do
        if tkey == key then
            return true
        end
    end
    return false
end

--[[ TODO: Move these to config.lua ]]
function mkfn_setting_get(setting)
    return function()
        return GameSettingGet(setting)
    end
end

--[[ TODO: Move these to config.lua ]]
function mkfn_setting_set(setting, astype)
    return function(value)
        local value_final = value_interpret(value, astype)
        GameSettingSet(setting, value_final)
    end
end



-- vim: set ts=4 sts=4 sw=4:
