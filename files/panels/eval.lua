--[[

The "Eval" Panel: Execute arbitrary code

This panel implements a simple Lua console for executing arbitrary code.

Available Functions & Variables:
  print(thing)    print to the panel, the game, the and game console
  self            reference to the EvalPanel instance
  host            reference to the parent panel controller instance
  env             reference to self.env for arbitrary use
  code            code being executed, as a string
  imgui           reference to the ImGui instance, if needed

  "Draw" functions: these functions are called once per frame with the
  imgui object as its single parameter, _after_ drawing the current
  panel and feedback text, if any.
    draw_func(imgui)

  add_draw_func(function) -> boolean
    Add a draw function that's called every frame; functions are
    tracked via tostring(function), and so adding a function more than
    once will have no effect. Returns true if the function was added
    (wasn't already present), false otherwise.

  remove_draw_func(function) -> boolean
    Remove a draw function; returns true if the function was present,
    false otherwise.

Available Objects:
  kae             libkae utility library
  EZWand          easy wand library
  nxml            small Noita XML parsing library
  smallfolk       data serialization/deserialization library

Behaviors:
  This panel permits modifying the global environment. New variables,
  functions, etc are stored in self.env.

Environment:
  self.env            table for whatever
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/kae_test/files/imguiutil.lua")

kae = dofile_once("mods/kae_test/files/lib/libkae.lua")
EZWand = dofile_once("mods/kae_test/files/lib/EZWand.lua")
nxml = dofile_once("mods/kae_test/files/lib/nxml.lua")
smallfolk = dofile_once("mods/kae_test/files/lib/smallfolk.lua")

-- Stash the environment for restricted functions
_G_STASH = {}
for key, val in pairs(_G) do
    _G_STASH[key] = val
end

INPUT_MIN_LINES = 4

EvalPanel = {
    id = "eval",
    name = "Eval",
    config = {
        show_keys = false,      -- should we display key events?
        histunique = true,      -- should history be kept globally unique?
        num_lines = 6,          -- how many lines should the edit window have?
        show_resize = false,    -- display the resize input element?
        run_funcs = false,      -- should we execute env.funcs every frame?
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
    self.host = host

    self.env.funcs = {}

    setmetatable(self, { __index = function(tbl, key) return rawget(tbl, key) end })
    --setmetatable(self, { __index = environ or _G } )
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
        self.error[2] = nil
        if debug and debug.traceback then
            self.error[2] = debug.traceback()
        end
    end

    self.env.player = get_players()[1]

    local cfunc, cerror
    if type(code) == "string" then
        -- Parse the code string into a function
        self.host:d(("eval %s"):format(code))
        cfunc, cerror = load(code)
        self.host:d(("cr = %s, ce = %s"):format(cfunc, cerror))
    elseif type(code) == "function" then
        cfunc, cerror = code, nil
    else
        cfunc = tostring(code)
        cerror = ("%s is not string/function"):format(type(code))
    end

    if type(cfunc) ~= "function" then
        return cfunc, cerror, nil, nil
    end

    -- This is the environment visible to the code (in addition to _G)
    local env_table = {
        ["print"] = _make_print_wrapper(self),
        ["self"] = self,
        ["env"] = self.env,
        ["host"] = self.host,
        ["code"] = code,
        ["imgui"] = self.env.imgui,

        ["player"] = self.env.player,
    }
    local env_meta = {
        __index = function(tbl, key)
            if rawget(tbl, key) ~= nil then
                return rawget(tbl, key)
            end
            if rawget(_G, key) ~= nil then
                return rawget(_G, key)
            end
            return rawget(_G_STASH, key)
        end,
        __newindex = function(tbl, key, value)
            rawset(tbl, key, value)
        end
    }

    -- tell libkae to use our custom print function
    if kae and kae.config then
        kae.config.printfunc = env_table["print"]
    end

    local env = setmetatable(env_table, env_meta)
    local func = setfenv(cfunc, env)
    local presult, pvalue = xpcall(func, code_on_error)
    return cfunc, cerror, presult, pvalue
end

--[[ Execute the given code, with diagnostic handling ]]
function EvalPanel:eval_full(code, config)
    local conf = config or {}
    self.env.exception = nil
    local cres, cerr, pres, pval = self:eval(code, self.env)
    if self.env.exception ~= nil then
        if self.env.exception[1] ~= nil then
            self.host:p(("error(): %s"):format(self.env.exception[1]))
        end
        if self.env.exception[2] ~= nil then
            self.host:p(("error(): %s"):format(self.env.exception[2]))
        end
    end
    if not conf.ephemeral then
        self:push_history()
    end
    if cerr ~= nil then
        self.host:p(("load() error: %s"):format(cerr))
    elseif pres ~= true and pval ~= nil then
        self.host:p(("eval() error: %s"):format(pval))
    elseif pval == "" then
        self.host:p("<no output>")
    elseif pval ~= nil then
        self.host:p(tostring(pval))
    end
end

--[[ Draw a custom menu for this panel ]]
function EvalPanel:draw_menu(imgui)
    local enable
    if imgui.BeginMenu(self.name) then
        enable = f_enable(self.config.run_funcs)
        if imgui.MenuItem(enable .. " frame functions") then
            self.config.run_funcs = not self.config.run_funcs
        end

        imgui.Separator()

        if imgui.MenuItem("Copy history") then
            local all_commands = ""
            for _, item in ipairs(self.history) do
                all_commands = all_commands .. item[1] .. "\r\n"
            end
            imgui.SetClipboardText(all_commands)
            self.host:p(("Copied %d commands to clipboard"):format(#self.history))
        end

        if imgui.MenuItem("Clear history") then
            self.history = {}
            self.histindex = 0
        end

        if imgui.MenuItem("Resize input") then
            self.config.show_resize = true
        end

        imgui.Separator()

        enable = f_enable(self.config.show_keys)
        if imgui.MenuItem(enable .. " key tracker") then
            self.config.show_keys = not self.config.show_keys
        end

        imgui.Separator()

        if imgui.MenuItem("Help") then
            self.host:p("Exec - executes code as-is")
            self.host:p("Eval - wraps code in 'return (%s)'")
            self.host:p("Clear - clears output text")
            self.host:p(("self.config.num_lines = %d"):format(self.config.num_lines))
        end

        if imgui.MenuItem("Show Variables") then
            self.host:p("var print = function(...)")
            self.host:p("var self, env, host, imgui")
            self.host:p("var code = string")
            self.host:p("var player = number")
            self.host:p(("self.config.num_lines = %d"):format(self.config.num_lines))
        end

        imgui.EndMenu()
    end
end

--[[ Draw this panel ]]
function EvalPanel:draw(imgui)
    self.env.imgui = imgui
    if type(self.code) ~= "string" then
        self.host:p(("ERROR: self.code is %s '%s' not string"):format(
            type(self.code), self.code))
        self.code = ""
    end

    local line_height = imgui.GetTextLineHeight()
    local ret, code = imgui.InputTextMultiline(
        "##Input",
        self.code,
        -line_height * 4,
        line_height * self.config.num_lines,
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
            if self.env.exception[1] ~= nil then
                self.host:p(("error(): %s"):format(self.env.exception[1]))
            end
            if self.env.exception[2] ~= nil then
                self.host:p(("error(): %s"):format(self.env.exception[2]))
            end
        end
        self:push_history()
        if cerr ~= nil then
            self.host:p(("load() error: %s"):format(cerr))
        elseif pres ~= true and pval ~= nil then
            self.host:p(("eval() error: %s"):format(pval))
        elseif pval == "" then
            self.host:p("<no output>")
        elseif pval ~= nil then
            self.host:p(tostring(pval))
        end
    end

    imgui.SameLine()
    if imgui.Button("Clear") then
        self.host:text_clear()
    end

    local hist_go = 0
    imgui.SameLine()
    if imgui.SmallButton("Prev") or imgui.IsKeyPressed(imgui.Key.UpArrow) then
        hist_go = -1
    end
    imgui.SameLine()
    if imgui.SmallButton("Next") or imgui.IsKeyPressed(imgui.Key.DownArrow) then
        hist_go = 1
    end

    -- If requested, show an input to change the number of lines available
    if not self.env.temp_num_lines then
        self.env.temp_num_lines = self.config.num_lines
    end
    if self.config.show_resize then
        ret, self.env.temp_num_lines = imgui.InputInt("Lines", self.env.temp_num_lines)
        if self.env.temp_num_lines < INPUT_MIN_LINES then
            self.env.temp_num_lines = INPUT_MIN_LINES
        end
        if imgui.Button("Apply") then
            self.config.num_lines = self.env.temp_num_lines
            self.config.show_resize = false
        end
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

    if self.env.funcs and self.config.run_funcs then
        local nfuncs = 0
        for fname, fobj in pairs(self.env.funcs) do
            nfuncs = nfuncs + 1
            imgui.Text(("Running %s"):format(fname))
            self:eval_full(fobj, {ephemeral=true})
        end
        if self.host.debugging then
            imgui.Text(("Invoked %d run function(s)"):format(nfuncs))
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
