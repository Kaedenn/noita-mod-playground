
--[[
--
-- The Logger
--
-- This file defines an "elaborate" logging interface for use in Noita
-- mods. Basic usage vaguely follows the following ideas:

local logger = KLog:new(KLog.LEVEL.I) -- or KLog:new("I") or KLog:new("INFO")
logger:configure({
    writers = {
        GamePrint,  -- must accept a string as a first argument
        io:stderr,  -- files are also allowed
    },
    formatter = "{file}:{line}: {level}: %s",
    -- alternatively, a function taking a record and returning a string
    -- is also allowed
    formatter = function(record) return tostring(record) end,
})

logger:config("writer", GamePrint) -- these functions must take a string
logger:config("writer", io.stderr) -- files are also allowed
logger:config("formatter", "{file}:{line}: {level}: %s")

logger:debug("this is a debug message")
logger:info("this is an info message")
logger:warn("this is a warning message")
logger:error("this is an error message")

-- Log records have the following attributes:
--  {
--      message = "the actual message",
--      args = {}, -- optional message format arguments
--      file = "the name of the source file",
--      line = number,
--      level = number,
--  }
--
-- Writers come in two flavors:
-- 1) Functions that take a string as the first argument
-- 2) io.file userdata objects (if io.type is usable)
--
-- Formatters also come in two flavors:
-- 1) Functions that take a "format record" and return a string
-- 2) Structured format strings
--
--

--
--]]
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/kae_test/files/functions.lua")

KLog = {
    -- Table of all loggers
    LOGGERS = {},

    LEVEL = {
        D = 5, DEBUG = 5,
        I = 10, INFO = 10,
        W = 15, WARN = 15,
        E = 20, ERROR = 20
    },

    _name = "global", -- This logger's name
    _level = nil, -- Current log level
    _writers = {}, -- Table of logging destinations
    _formatters = {}, -- Table of record -> string formatters

    is_level = function(self, value)
        if type(value) == "number" then
            return true
        end
        if type(value) == "string" and KLog.LEVEL[value] ~= nil then
            return true
        end
        return false
    end,

    lookup_level = function(self, value)
        if type(value) == "number" then return value end
        if type(value) == "string" and self:is_level(value) then
            return self.LEVEL[value]
        end
        return nil
    end,
}

function KLog:new(name)
    self._name = name or "global"
    KLog.LOGGERS[self._name] = self
    self._level = KLog.LEVEL.I
    return self
end

-- Bulk configure the logger; returns false if there were any issues
function KLog:configure(config)
    local success = true
    for _, value in ipairs(config) do
        if not self:config(nil, value) then
            success = false
        end
    end

    for key, value in pairs(config) do
        if not self:config(key, value) then
            success = false
        end
    end
    return success
end

-- Configure one item; returns true on success, false on failure
function KLog:config(key, value)
    local vtype = type(value)
    if key == "level" then -- Logging level
        if vtype == "string" then
            if KLog.LEVEL[value] ~= nil then
                self._level = KLog.LEVEL[value]
                return true
            end
            return false, "invalid level " .. value
        elseif vtype == "number" then
            self._level = value
            return true
        end
        return false, "level invalid type " .. vtype
    elseif key == "writer" then -- Single writer
        if vtype == "userdata" then
            if io and io.type == "file" then
                table.insert(self._writers, value)
                return true
            end
        elseif vtype == "function" then
            table.insert(self._writers, value)
            return true
        end
        return false, "writer invalid type"
    elseif key == "formatter" then -- Single formatter
        if vtype == "string" then
            -- TODO: format string
            return true
        elseif vtype == "function" then
            table.insert(self._formatters, value)
            return true
        end
        return false, "formatter bad type"
    elseif key ~= nil then -- Unsupported key
        return false, "invalid key " .. key
    elseif self:config("level", value) then -- maybe it's a level?
        return true
    elseif self:config("writer", value) then -- maybe it's a target?
        return true
    end
    return false, ("value parse failed '%s' type %s"):format(value, vtype)
end

--[[ OLD LOGGING API BELOW ]]--

K_CONFIG_LOG_ENABLE = "kae_logging"
K_ON = "1"
K_OFF = "0"

-- Print a message to both the game and to the console.
function kae_print(msg)
    GamePrint(msg)
    print(msg)
end

-- Returns true if logging is enabled, false otherwise.
function kae_logging()
    return GlobalsGetValue(K_CONFIG_LOG_ENABLE, K_OFF) ~= K_OFF
end

-- Enable or disable logging
function kae_set_logging(enable)
    if enable then
        GlobalsSetValue(K_CONFIG_LOG_ENABLE, K_ON)
        kae_log("Debugging is now enabled")
    else
        kae_log("Disabling debugging")
        GlobalsSetValue(K_CONFIG_LOG_ENABLE, K_OFF)
    end
end

-- Display a logging message if logging is enabled.
function kae_log(msg)
    if kae_logging() then
        return kae_print("DEBUG: " .. msg)
    end
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
