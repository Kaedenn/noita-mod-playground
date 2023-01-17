--[[
-- The "Eval" Panel: Evaluate arbitrary code
--
--]]

dofile_once("data/scripts/lib/utilities.lua")

EvalPanel = {
    id = "eval",
    name = "Eval",
    config = {
        size = 256,     -- size of the input box
    },
    last_error = {nil, nil}, -- most recent error
    host = {},  -- reference to the controlling Panel class
    code = "",  -- current value of the code input box
    text = {},  -- output lines
}

-- Execute code with an optional additional environment object. Returns:
--      parse result, parse error, eval result, eval error
--
-- On parse failure, both eval result and eval error will be nil.
--
-- On eval error, obtain the error message and traceback via env.exception:
--      env.exception[1]    error message
--      env.exception[2]    traceback string
function EvalPanel:eval(code, penv)
    local env = penv or {}

    local function code_on_error(errmsg)
        GamePrint(errmsg)
        table.insert(self.text, errmsg)
        if env then env.exception = {errmsg, debug.traceback()} end
    end

    self:d(("eval %s"):format(code))
    local cfunc, cerror = load(code)
    self:d(("cr = %s, ce = %s"):format(cfunc, cerror))
    if type(cfunc) ~= "function" then
        return cfunc, cerror, nil, nil
    end

    if type(cfunc) == "function" then
        local presult, pvalue = xpcall(cfunc, code_on_error)
        return cfunc, cerror, presult, pvalue
    end
    return cfunc, cerror, nil, nil
end

-- Helper functions
function EvalPanel:_conf_toggle_str(key)
    local mvalue = key:gsub("^[a-z]", function(chr) return chr:upper() end)
    if self.config[key] then
        mvalue = ("%s [*]"):format(mvalue)
    end
    return mvalue
end

function EvalPanel:d(message)
    self.host:d(message)
end

-- Initialize this panel
function EvalPanel:init(environ, host)
    self.env = environ or {}
    self.host = host or {}
    setmetatable(self, { __index = environ or _G })
    return self
end

-- Is debugging enabled?
function EvalPanel:debugging()
    return self.host.debugging
end

-- Draw a custom menu for this panel
function EvalPanel:draw_menu(imgui)
    if imgui.BeginMenu(self.name) then
        imgui.EndMenu()
    end
end

-- Draw this panel
function EvalPanel:draw(imgui)
    imgui.Text("Eval")
    local ret, code = imgui.InputText("", self.code, self.config.size or 256)
    self.code = code

    if imgui.Button("Run") then
        self.host:d(("exec(%q)"):format(self.code))
    end
    imgui.SameLine()
    if imgui.Button("Clear") then
        self.code = ""
        self.text = {}
    end

end

function EvalPanel:configure(config)
    for key, value in pairs(config) do
        self.config[key] = value
    end
end

return EvalPanel

-- vim: set ts=4 sts=4 sw=4:
