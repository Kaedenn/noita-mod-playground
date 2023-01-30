--[[
-- The "Eval" Panel: Execute arbitrary code
--
-- This panel implements a simple (currently line-based) Lua console for
-- executing arbitrary code.
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile("mods/kae_test/files/imguiutil.lua")

--[[ TODO:
-- Proper history traversal on up/down arrow keys
--]]

--[[ The panel object. This file must return this object. ]]
EvalPanel = {
    id = "eval",
    name = "Eval",
    config = {
        size = 256,     -- size of the input box
        show_keys = false,  -- should we display key events?
    },
    last_error = {nil, nil}, -- most recent error
    host = nil,     -- reference to the controlling Panel class
    env = {},       -- persistent environment for arbitrary storage
    code = "",      -- current value of the code input box

    history = {},   -- table of past commands
    histindex = 0,  -- selected history index for traversal
}

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
-- Errors raised by the code can be obtained via examining self.last_error.
--]]
function EvalPanel:eval(code)

    -- Called whenever the code raises error
    local function code_on_error(errmsg)
        GamePrint(errmsg)
        self.host:p(errmsg)
        self.last_error[1] = errmsg
        self.last_error[2] = debug.traceback()
    end

    -- Parse the code string into a function
    self.host:d(("eval %s"):format(code))
    local cfunc, cerror = load(code)
    self.host:d(("cr = %s, ce = %s"):format(cfunc, cerror))
    if type(cfunc) ~= "function" then
        return cfunc, cerror, nil, nil
    end

    -- Inject a temporary print function
    local real_print = _G.print
    print = function(...)
        -- Always call the real print function
        pcall(real_print, ...)
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
        self.host:p(line)
    end

    local presult, pvalue = nil, nil
    if type(cfunc) == "function" then
        _G.self = self
        self.env.player = get_players()[1]
        presult, pvalue = xpcall(cfunc, code_on_error)
        _G.self = nil
    end
    print = real_print

    return cfunc, cerror, presult, pvalue
end

--[[ Initialize this panel ]]
function EvalPanel:init(environ, host)
    self.env = environ or {}
    self.host = host or {}
    setmetatable(self, { __index = environ or _G })
    return self
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
        end

        if imgui.MenuItem("Clear history") then
            self.history = {}
            self.histindex = 0
        end

        imgui.Separator()

        if imgui.MenuItem("Key tracker") then
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
    -- FIXME: Changes to self.code don't seem to propagate well
    local ret, code = imgui.InputText("", self.code, self.config.size or 256)
    if code and code ~= "" then
        self.code = code
    end

    local exec_code = false
    if imgui.Button("Run") then
        exec_code = true
    end

    if imgui.IsKeyPressed(imgui.Key.Enter) then
        exec_code = true
    end

    if exec_code then
        self.env.exception = nil
        self.env.imgui = imgui
        local cres, cerr, pres, pval = self:eval(self.code, self.env)
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

    -- Recall the previous command
    if imgui.IsKeyPressed(imgui.Key.UpArrow) then
        if self.histindex > 1 then
            self.histindex = self.histindex - 1
            self.code = self.history[self.histindex][1]
        end
    end

    -- Recall the next command
    if imgui.IsKeyPressed(imgui.Key.DownArrow) then
        if self.histindex < #self.history then
            self.histindex = self.histindex + 1
            self.code = self.history[self.histindex][1]
        end
    end

    -- Debugging!
    if self.host.debugging then
        imgui.Text(("History: %s i=%s"):format(#self.history, self.histindex))
        for idx, entry in ipairs(self.history) do
            imgui.Text(("H[%d]: '%s'"):format(idx, entry))
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
