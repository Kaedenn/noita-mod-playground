
dofile_once("data/scripts/lib/utilities.lua")
dofile("mods/kae_test/files/functions.lua")

K_CONFIG_LOG_ENABLE = "kae_logging"
K_ON = "1"
K_OFF = "0"

--[[
local log_settings = {}
function add_level(name, test_func, set_func, format, writer)
    local def = {
        name = name,
        test = test_func,
        set = set_func,
        format = format,
        writer = writer or GamePrint
    }

    if type(format) == "string" then
        def.format = function(message) return string.format(format, message) end
    elseif type(format) ~= "function" then
        error(("format must be string or function; got %s"):format(type(format)))
    end

    if writer ~= nil then
        if type(writer) ~= "function" and io.type(writer) == "file" then
            def.writer = function(line)
                file:write(line)
                if not (line):match("[\r]?\n$") then
                    file:write("\r\n")
                end
            end
        elseif type(writer) ~= "function" then
            error(("writer must be function or file; got %s"):format(type(writer)))
        end
    end

    log_settings[name] = def
end

function klog_init()
    add_level("debug",
        mkfn_setting_get(K_CONFIG_LOG_ENABLE),
        mkfn_setting_set(K_CONFIG_LOG_ENABLE, "string")
        "debug: %s")
    add_level("info",
        function() return true end
        function(enable) end,
        "info: %s")
end

function klog_enabled(level)
    if log_settings[level] ~= nil then
        if log_settings[level].test() then
            return true
        end
    end
    return false
end

function klog_set_enable(level, enable)
    if log_settings[level] ~= nil then
        log_settings[level].set(enable)
    end
end

function klog_enable(level) klog_set_enable(level, true) end

function klog_disable(level) klog_set_enable(level, false) end

function klog(level, message)
    if klog_enabled(level) then
        local ldef = log_settings[level]
        ldef.writer(ldef.format(message))
    end
end
--]]

-- Return true_val if true, false_val otherwise
function ifelse(cond, true_val, false_val)
    if cond then
        return true_val
    end
    return false_val
end

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
