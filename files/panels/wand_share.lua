--[[
-- "Wand Share" Panel
--
-- This panel investigates the feasibility of exporting and importing
-- wands for sharing to other players.
--
-- Intended features:
--
-- WAND EXPORT
--
--  Click a button to serialize the current wand. The resulting string
--  will appear in an input box that the player can then select and
--  Ctrl+C.
--
--  The following export methods are being considered in addition to
--  the input box:
--    1. (Checkbox) export the wand to the clipboard
--    2. (GUI) export the wand to the user's computer (Maybe?)
--    3. Export the wand and upload to a webserver (Maybe?)
--
-- WAND IMPORT
--
--  Click a button to de-serialize a wand and load it into one of the
--  following locations:
--    1. The player's wand inventory (if there's a free slot)
--    2. The player's held wand, overwriting the wand entirely
--    3. The world
--    4. Into the SpellLab wand presets (Maybe?)
--
--  The following import methods are being considered:
--
--    1. From the same text box as above
--    2. From the clipboard
--    3. From a website (Maybe?)
--    4. From a text fle on the user's computer (Maybe?)
--
-- Configuration:
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/kae_test/files/functions.lua")
dofile_once("mods/kae_test/files/wandlib.lua")

CONFIG = {
    debug = false,
    text_size = 3000,
}

_data = {
    current_text = "",
}

local lines = {}
function add_line(line) table.insert(lines, line) end

function mdebug(msg)
    if CONFIG.debug then
        add_line(("D: %s"):format(msg))
    end
end

function on_error(msg)
    add_line(debug.traceback())
    if msg then
        add_line(("E: %s"):format(msg))
    end
end

function count_table(tbl, entry)
    local ecount = 0
    for _, value in ipairs(tbl) do
        if value == entry then
            ecount = ecount + 1
        end
    end
    return ecount
end

-- Required function: initialize this panel
function init() end

-- Required function: draw this panel (assumes imgui.Begin() was called)
function draw(imgui)
    imgui.Text("Wand Export/Import")
    local ret, intext = imgui.InputText("", _data.current_text, CONFIG.text_size)
    if ret then _data.current_text = intext end

    if imgui.Button("Dump") then
        -- TODO
    end
    imgui.SameLine()
    if imgui.Button("Load") then
        -- TODO
    end

    if imgui.Button("Import to World") then
        -- TODO
    end

    --[[
    imgui.Text("Eval"); imgui.SameLine()

    local ret = false
    ret, eval_input_text = imgui.InputText("", eval_input_text, TEXT_SIZE)

    if imgui.Button("Run") then
        table.insert(command_history, eval_input_text)
        command_history_pos = #command_history

        mdebug(("exec: %q"):format(eval_input_text))
        local cresult, cerror = load(eval_input_text)
        mdebug(("load: r=%s e=%s"):format(cresult, cerror))
        if type(cresult) == "function" then
            local presult, pvalue = xpcall(cresult, on_error)
            mdebug(("xpcall(...): r=%s v=%s"):format(presult, pvalue))
            if presult then
                add_line(tostring(pvalue))
            else
                add_line(("E: value[%s] %s not function"):format(type(pvalue), pvalue))
            end
        else
            add_line(("E: load result=%s error=%s"):format(cresult, cerror))
        end
    end
    imgui.SameLine()
    if imgui.Button("Clear") then
        -- Use table.remove as to keep the panel._.lines consistent
        while #lines > 0 do table.remove(lines) end
    end

    local recall_value = nil
    if imgui.Button("Prior") then recall_value = history_recall_previous() end
    imgui.SameLine()
    if imgui.Button("Next") then recall_value = history_recall_next() end
    imgui.SameLine()
    imgui.Text("History recall")
    if recall_value ~= nil then
        eval_input_text = recall_value
    end

    for _, line_rec in ipairs(lines) do
        if type(line_rec) == "table" then
            for lnr, line in ipairs(line_rec) do
                imgui.Text(line)
            end
        else
            imgui.Text(line_rec)
        end
    end
    --]]
end

function _apply_config(key, val)
end

-- Required function: set or update this panel's configuration
function configure(config)
    for key, value in pairs(config) do
        _apply_config(key, value)
    end
    return CONFIG
end

return {
    id = "eval",
    name = "Eval",
    init = init,
    draw = draw,
    configure = configure,
    _ = {
        lines = lines,
    }
}

-- vim: set ts=4 sts=4 sw=4 tw=79:
