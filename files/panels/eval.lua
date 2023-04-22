--[[

The "Eval" Panel: Execute arbitrary code

This panel implements a simple (currently line-based) Lua console for
executing arbitrary code.

Features:
    print(...) will output to the panel, to the game, and to the game's console
    self.draw is a table of draw functions, called every frame:
        function my_draw_func(imgui) ... end
        table.insert(self.draw, my_draw_func)   to add the function
        table.remove(self.draw, my_draw_func)   to remove the function

Behaviors:
    This panel permits modifying the global environment. New variables,
    functions, etc are always stored in the global table. The following
    variables and functions are implicitly available:
        print(thing)    print to the panel, the game, the and game console
        self            reference to the EvalPanel instance
        env             reference to self.env
        host            reference to the parent panel controller instance
        code            code being executed, as a string

Configuration:
    show_keys:boolean   display keypresses as they happen

Environment:
    self.env            table for whatever
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile("mods/kae_test/files/imguiutil.lua")

EZWand = dofile("mods/kae_test/files/lib/EZWand.lua")
nxml = dofile("mods/kae_test/files/lib/nxml.lua")
smallfolk = dofile("mods/kae_test/files/lib/smallfolk.lua")

--[[ TODO:
-- Proper history traversal on up/down arrow keys
--]]

EvalPanel = {
    id = "eval",
    name = "Eval",
    config = {
        show_keys = false,  -- should we display key events?
        histunique = true,  -- should history be kept globally unique?
    },
    error = {nil, nil}, -- most recent error
    host = nil,         -- reference to the controlling Panel class
    env = nil,          -- persistent environment for arbitrary storage
    code = "",          -- current value of the code input box

    history = {},       -- table of past commands
    histindex = 0,      -- selected history index for traversal
}

--[[ Initialize this panel ]]
function EvalPanel:init(environ, host)
    self.env = environ or {}
    self.host = host or {}

    self.env.draw_funcs = {}

    setmetatable(self, { __index = environ or _G })
    return self
end

--[[ Create the "print" function wrapper ]]
function _make_print_wrapper(evalobj)
    local real_print = _G.print
    return function(...)
        -- Always call the real print function
        pcall(real_print, ...)
        pcall(GamePrint, ...)
        local line = ""
        local items = {...}
        for i, item in ipairs(items) do
            if i ~= 1 then
                line = line .. "\t"
            end
            line = line .. tostring(item)
        end
        if #line == 0 then
            line = "<empty>"
        end
        evalobj.host:p(line)
    end
end

function EvalPanel:push_history()
    if #self.history > 0 then
        if self.history[#self.history][1] == self.code then
            return false
        end
    end
    table.insert(self.history, {self.code})
    self.histindex = #self.history
    return true
end

--[[ Execute code
--  Return value:
--      parse result    code function, result of load()[1]
--      parse error     error message, result of load()[2]
--      eval result     true on success, false on error, nil on parse failure
--      value           value returned by code; nil on none or error
--
-- Errors raised by the code can be obtained via examining self.error.
--]]
function EvalPanel:eval(code)

    -- Called whenever the code raises error
    local function code_on_error(errmsg)
        GamePrint(errmsg)
        self.host:p(errmsg)
        self.error[1] = errmsg
        self.error[2] = debug.traceback()
    end

    self.env.player = get_players()[1]

    -- Parse the code string into a function
    self.host:d(("eval %s"):format(code))
    local cfunc, cerror = load(code)
    self.host:d(("cr = %s, ce = %s"):format(cfunc, cerror))
    if type(cfunc) ~= "function" then
        return cfunc, cerror, nil, nil
    end

    -- Apply a custom environment
    local env_table = {
        ["print"] = _make_print_wrapper(self),
        ["self"] = self,
        ["env"] = self.env,
        ["host"] = self.host,
        ["code"] = code,
        ["imgui"] = self.env.imgui
    }
    local env_meta = {
        __index = function(tbl, key)
            if rawget(tbl, key) ~= nil then
                return rawget(tbl, key)
            end
            return rawget(_G, key)
        end,
        __newindex = function(tbl, key, value)
            if rawget(tbl, key) ~= nil then -- XXX would this ever be true?
                rawset(tbl, key, value)
            else
                rawset(_G, key, value)
            end
        end
    }

    local env = setmetatable(env_table, env_meta)
    local func = setfenv(cfunc, env)
    local presult, pvalue = nil, nil
    presult, pvalue = xpcall(func, code_on_error)
    return cfunc, cerror, presult, pvalue
end

--[[ Draw a custom menu for this panel ]]
function EvalPanel:draw_menu(imgui)
    if imgui.BeginMenu(self.name) then
        if imgui.MenuItem("Copy history") then
            local all_commands = ""
            for _, item in ipairs(self.history) do
                all_commands = all_commands .. item[1] .. "\n"
            end
            imgui.SetClipboardText(all_commands)
            self.host:p(("Copied %d commands to clipboard"):format(#self.history))
        end

        if imgui.MenuItem("Clear history") then
            self.history = {}
            self.histindex = 0
        end

        imgui.Separator()

        local enable = f_enable(self.config.show_keys)
        if imgui.MenuItem(enable .. " key tracker") then
            self.config.show_keys = not self.config.show_keys
        end
        imgui.EndMenu()
    end
end

--[[ Draw this panel ]]
function EvalPanel:draw(imgui)
    if type(self.code) ~= "string" then
        self.host:p(("ERROR: self.code is %s '%s' not string"):format(
            type(self.code), self.code))
        self.code = ""
    end
    --local ret, code = imgui.InputText("", self.code, self.config.size or 256)
    local line_height = imgui.GetTextLineHeight()
    local ret, code = imgui.InputTextMultiline(
        "##Input",
        self.code,
        -line_height * 4,
        line_height * 3,
        imgui.InputTextFlags.EnterReturnsTrue
    )
    if code and code ~= "" then
        self.code = code
    end

    local exec_code = ret or false
    if imgui.Button("Exec") then
        exec_code = true
    end

    imgui.SameLine()
    if imgui.Button("Eval") then
        exec_code = true
        code = ("return (%s)"):format(self.code)
    end

    --[[if imgui.IsKeyPressed(imgui.Key.Enter) then
        exec_code = true
    end]]

    if exec_code then
        self.env.exception = nil
        self.env.imgui = imgui
        local cres, cerr, pres, pval = self:eval(code, self.env)
        if self.env.exception ~= nil then
            self.host:p(("error(): %s"):format(self.env.exception[1]))
            self.host:p(("error(): %s"):format(self.env.exception[2]))
        end
        self:push_history()
        if cerr ~= nil then
            self.host:p(("load() error: %s"):format(cerr))
        elseif pres ~= true then
            self.host:p(("eval() error: %s"):format(pval))
        elseif pval ~= nil then
            self.host:p(tostring(pval))
        end
    end

    imgui.SameLine()
    if imgui.Button("Clear") then
        self.host:text_clear()
    end

    imgui.SameLine()
    if imgui.Button("Clear All") then
        self.code = ""
        self.host:text_clear()
    end

    local hist_go = 0
    if imgui.IsKeyPressed(imgui.Key.UpArrow) then
        hist_go = -1
    elseif imgui.IsKeyPressed(imgui.Key.DownArrow) then
        hist_go = 1
    end
    imgui.SameLine()
    if imgui.SmallButton("Prev") then
        hist_go = -1
    end
    imgui.SameLine()
    if imgui.SmallButton("Next") then
        hist_go = 1
    end

    -- Recall the previous command or the next command
    if hist_go ~= 0 and #self.history ~= 0 then
        self.histindex = clamp(self.histindex + hist_go, 1, #self.history)
        self.code = self.history[self.histindex][1]
    end

    -- Debugging!
    if self.host.debugging then
        imgui.Text(("History: %s i=%s g=%s"):format(#self.history,
                self.histindex, hist_go))
        for idx, entry in ipairs(self.history) do
            imgui.Text(("H[%d]: [%d]"):format(idx, #entry[1]))
        end
        imgui.Text(("self.code = '%s'"):format(self.code))
    end

    if self.config.show_keys then
        local keys_pressed = {}
        local keys_down = {}
        for _, keyname in ipairs(ImguiKeys) do
            if keyname ~= "COUNT" then
                local keycode = imgui.Key[keyname]
                if imgui.IsKeyPressed(keycode) then
                    table.insert(keys_pressed, keyname)
                end
                if imgui.IsKeyDown(keycode) then
                    table.insert(keys_down, keyname)
                end
            end
        end

        if #keys_pressed > 0 then
            imgui.Text("Pressed: " .. table.concat(keys_pressed, " "))
        end

        if #keys_down > 0 then
            imgui.Text("Down: " .. table.concat(keys_down, " "))
        end
    end
end

--[[ Apply a configuration table to this panel ]]
function EvalPanel:configure(config)
    for key, value in pairs(config) do
        self.config[key] = value
    end
end

return EvalPanel

-- vim: set ts=4 sts=4 sw=4:
