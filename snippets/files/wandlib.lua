-- Helper library for interacting with wands
--
-- Functions beginning with "wl_" are helper functions.
--
-- WL_FORMAT_CURRENT
--      Serialization format version. Incremented when the serialization
--      format changes in a way that'd break backwards-compatibility.
--      This is to ensure wands are deserialized using the same logic
--      that serialized them.
--
-- wl_add_debug(func)
--      Add a debugging function. This function will be called with a
--      single string argument.
--
-- serialize_wand(wand_object[, format_version])
--      Given a wand entity and an optional format version argument,
--      generate and return a string that completely and accurately
--      describes the given wand. The resulting string will also include
--      the format version that was used.
--
--      If format_version is omitted or invalid, then the current
--      WL_FORMAT_CURRENT is used.
--
--      Example uses:
--          wand_string = serialize_wand(wand_object)
--          wand_string = serialize_wand(wand_object, WL_FORMAT_1)
--          wand_string = serialize_wand(wand_object, "WL_FORMAT_1")
--
-- deserialize_wand(wand_string)
--      Given a serialized wand string, deserialize it and return two
--      values: the format version (deduced or otherwise) and the wand
--      entity.
--
--      Example use:
--          wand = deserialize_string(wand_string)
--          wand = deserialize_string(wand_string, WL_FORMAT_1)
--          wand, format_ver = deserialize_wand(wand_string)

dofile_once("data/scripts/gun/gun.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/kae_test/files/functions.lua")

-- Valid serialization formats
WL_FORMAT_1 = 1
WL_FORMATS = {
    [WL_FORMAT_1] = WL_FORMAT_1,
    WL_FORMAT_1 = WL_FORMAT_1,
}

-- Serialization version number to ensure we are backwards-compatible.
WL_FORMAT_CURRENT = WL_FORMAT_1;

-- Configuration object for instance-volatile configuration settings.
_wandlib_config = { debug_funcs = {} }

-- HELPER FUNCTIONS

-- Called whenever there's an error that shouldn't terminate the entire
-- execution.
function wl_error(message, traceback)
    if traceback == nil then traceback = debug.traceback() end
    print(traceback)
    GamePrint(traceback)
    print(message)
    GamePrint(message)
end

-- Add a debugging function. This function is called with a single
-- string argument. For example,
--      func(("Format version: %d"):format(WL_FORMAT_CURRENT))
function wl_add_debug(func)
    table.insert(debug_funcs, func)
end

function wl_debug(msg)
    for _, func in ipairs(_wandlib_config.debug_func) do
        -- These functions are untrusted and may fail. Don't allow that
        -- to break our operations.
        local fstatus, fresult = pcall(func, msg)
        if not fstatus then
            wl_error(tostring(fresult), debug.traceback())
        end
    end
end

-- actual_format, defaulted = wl_verify_format(desired_format)
function wl_verify_format(format_ver)
    if format_ver == nil then
        return WL_FORMAT_CURRENT, true
    end
    if WL_FORMATS[format_ver] == nil then
        wl_error(("Invalid format '%s'"):format(format_ver))
        wl_error(("Using format '%s'"):format(WL_FORMAT_CURRENT))
        return WL_FORMAT_CURRENT, false
    end
    return format_ver, false
end

function serialize_wand(wand, format_ver)
    local fmtver, defaulted = wl_verify_format(format_ver)
    wl_debug(("Encode '%s' using v%s"):format(wand, fmtver))
    return ENCODERS[fmtver](wand, fmtver, defaulted)
end

function deserialize_wand(wand, format_ver)
    local fmtver, defaulted = wl_verify_format(format_ver)
    wl_debug(("Decode '%s' using v%s"):format(wand, fmtver))
    return DECODERS[fmtver](wand, fmtver, defaulted)
end

ENCODERS = {
    [SER_FORMAT_1] = function(wand, format_hint, defaulted)
        -- TODO
    end,
}

DECODERS = {
    [SER_FORMAT_1] = function(wand, format_hint, defaulted)
        -- TODO
    end
}

-- vim: set ts=4 sts=4 sw=4:
