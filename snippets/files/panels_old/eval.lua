--[[
-- "Eval" Panel
--
-- Configuration:
--      indent="string"     Set indent to string
--      indent=number       Set indent to the number of spaces
--      histmax=number      Set the maximum history size to number
--      histmax=-1          Set the maximum history size to unlimited
--          HISTMAX_UNLIMITED
--      histmax=0           Disable storing history
--          HISTMAX_DISABLED
--      histignore="term"   Configure commands to ignore when adding history
--          "="         Clear histignore
--          "=CMD"      Clear histignore and add CMD as its only entry
--          "+CMD"      Add CMD if it doesn't already exist
--          "-CMD"      Remove CMD; successful even when CMD isn't present
--          "CMD"       Equivalent to "+CMD"
--      ignorespace=boolean If true, ignore commands starting with a space
--      ignoredupes=boolean If true, prevent duplicate history entries
--]]

-- TODO: History recall

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/kae_test/files/functions.lua")

HISTMAX_UNLIMITED = -1      -- no limit on history recall
HISTMAX_DISABLED = 0        -- disable history recall

CONFIG = {
    indent = "  ",
    debug = false,
    histmax = HISTMAX_UNLIMITED,
    histcontrol = {
        histignore = {},
        ignorespace = false,
        ignoredupes = false,
        erasedupes = false,
    }
}
TEXT_SIZE = 256

local lines = {}
local eval_input_text = ""

local command_history = {}
local command_history_pos = 0

local function eval_with_env(code, env)
    if env == nil then env = {} end
    local cresult, cerror = load(code)
    if type(cresult) == "function" then
        local code_func = setfenv(cresult, setmetatable(env, { __index = _G }));
        local presult, pvalue = xpcall(code_func, on_error)
        return cresult, cerror, presult, perror
    end
    return cresult, cerror, nil, nil
end

function add_line(line)
    table.insert(lines, line)
end

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

function count_history(command) return count_table(command_history, command) end

function draw_lines(imgui)
    local indent = CONFIG.indent or "  "
    imgui.Text(("Lines: %d"):format(#lines))
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

function add_history(command)
    local hcon = CONFIG.histcontrol
    local ignore = false
    if CONFIG.histmax == HISTMAX_DISABLED then
        ignore = true
    elseif CONFIG.histmax ~= HISTMAX_UNLIMITED and #command_history >= CONFIG.histmax then
        ignore = true
    elseif hcon and hcon.ignorespace and command:match("^ ") then
        ignore = true
    elseif hcon and hcon.histignore and count_table(hcon.histignore, command) > 0 then
        ignore = true
    elseif hcon and hcon.ignoredupes and count_history(command) > 0 then
        if hcon.erasedupes then
            while table.remove(command_history, command) == command do end
        else
            ignore = true
        end
    end

    if not ignore then
        table.insert(command_history, command)
        command_history_pos = #command_history
    end
end

function history_recall_previous()
    if #command_history == 0 then
        return nil
    end

    command_history_pos = clamp(command_history_pos - 1, 1, #command_history)
    return command_history[command_history_pos]
end

function history_recall_next()
    if #command_history == 0 then
        return nil
    end

    command_history_pos = clamp(command_history_pos + 1, 1, #command_history)
    return command_history[command_history_pos]
end

function history_recall_current()
    if #command_history == 0 or command_history_pos == 0 then
        return nil
    end

    return command_history[command_history_pos]
end

-- Required function: initialize this panel
function init(host_env)
    add_line(("init('%s')"):format(host_env))
end

-- Required function: draw this panel (assumes imgui.Begin() was called)
function draw(imgui, host_env)
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

end

function _parse_flag(value)
    if #value == 0 then return true end
    return as_boolean(value)
end

function _apply_config(key, val)
    local value = val
    if key == "debug" then
        CONFIG.debug = _parse_flag(value)
    elseif key == "indent" then
        if type(value) == "number" then
            value = string.rep(" ", value)
        elseif type(value) ~= "string" then
            value = tostring(value)
        end
        CONFIG.indent = value
    elseif key == "histmax" then
        if type(value) ~= "number" then
            value = tonumber(value)
        end
        CONFIG.histmax = value
    elseif key:match("histignore") then
        if type(value) ~= "string" then
            value = tostring(value)
        end
        local action = value:sub(1, 1)
        local command = value:sub(2)
        if action == '-' then
            table.remove(CONFIG.histcontrol.histignore, command)
        else
            if action == '=' then
                while #CONFIG.histcontrol.histignore > 0 do
                    table.remove(CONFIG.histcontrol.histignore)
                end
            elseif action ~= "+" then -- no action; assume '+'
                command = value
            end
            if count_table(CONFIG.histcontrol.histignore, command) == 0 then
                table.insert(CONFIG.histcontrol.histignore, command)
            end
        end
    elseif key:match("ignorespace") or key:match("ignoreboth") then
        local ignore = _parse_flag(value)
        if ignore ~= nil then
            CONFIG.histcontrol.ignorespace = ignore
        end
    elseif key:match("ignoredupes") or key:match("ignoreboth") then
        local ignore = _parse_flag(value)
        if ignore ~= nil then
            CONFIG.histcontrol.ignoredupes = ignore
        end
    elseif key:match("erasedupes") then
        local erase = _parse_flag(value)
        if erase ~= nil then
            CONFIG.histcontrol.erasedupes = erase
        end
    end
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
        CONFIG = CONFIG,
        lines = lines,
        command_history = command_history,
        add_history = add_history,
        history_recall_previous = history_recall_previous,
        history_recall_next = history_recall_next,
        history_recall_current = history_recall_current,
    }
}

-- vim: set ts=4 sts=4 sw=4 tw=79:
