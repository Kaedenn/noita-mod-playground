--[[
-- "Summon" Panel
--
-- Configuration: TBD
--
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/kae_test/files/functions.lua")

CONFIG = {
    debug = false,
}

local lines = {}
function add_line(line) table.insert(lines, line) end

function mdebug(msg)
    if CONFIG.debug then
        add_line(("D: %s"):format(msg))
    end
end

function draw_lines(imgui)
    for idx, entry in ipairs(lines) do
        if type(entry) == "table" then
            for lnum, line in ipairs(entry) do
                imgui.Text(("%s%s"):format(indent, line))
            end
        else
            imgui.Text(("%s"):format(entry))
        end
    end
end

function init() end

function draw(imgui)
end

function configure(config)
    for key, value in pairs(config) do
        CONFIG[key] = value
    end
    return CONFIG
end

return {
    id = "summon",
    name = "Summon",
    init = init,
    draw = draw,
    configure = configure,
    _ = {
        CONFIG = CONFIG,
        lines = lines,
    },
}
