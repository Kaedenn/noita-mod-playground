
dofile_once("data/scripts/lib/utilities.lua")

CONFIG = {indent = "  ", mdebug = false}
TEXT_SIZE = 256

local lines = {}
setmetatable(lines, { __call = function(self, arg)
    table.insert(self, arg)
end })

function mdebug(msg)
    if CONFIG.debug then
        lines(("D: %s"):format(msg))
    end
end

function on_error(msg)
    lines(debug.traceback())
    if msg then
        lines(("E: %s"):format(msg))
    end
end

function draw_lines(imgui)
    local indent = CONFIG.indent or "  "
    for idx, entry in ipairs(lines) do
        if type(entry) == "table" then
            for lnum, line in pairs(entry) do
                imgui.Text(("%s%s"):format(indent, line))
            end
        else
            imgui.Text(("%s"):format(entry))
        end
    end
end

-- Required function: initialize this panel
function init() end

-- Required function: draw this panel (assumes imgui.Begin() was called)
function draw(imgui)
    -- Orbs

    -- Bosses

    -- Achievements?

    draw_lines(imgui)
end

-- Required function: set or update this panel's configuration
function configure(config)
    for key, value in pairs(config) do
        if key == "indent" then CONFIG.indent = value
        elseif key == "debug" then CONFIG.debug = value
        end
    end
end


return {
    id = "progress",
    name = "Progress",
    init = init,
    draw = draw,
    configure = configure
}

-- vim: set ts=4 sts=4 sw=4 tw=79:
