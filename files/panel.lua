--[[
-- Panel GUI System (v2)
--
-- This script implements the "panels" API, with each "panel" being a separate
-- user-defined GUI layout selected by menu. 
--
-- Usage:
--  local PanelLib = dofile("files/panel.lua")
--  local Panel = PanelLib:init()
--
-- Panels are classes with the following entries:
-- panel.id = "string"     (required)
-- panel.name = "string"   (optional; defaults to panel.id)
-- panel:init()            (optional)
-- panel:draw(imgui)       (required)
-- panel:draw_menu(imgui)  (optional)
-- panel:configure(table)  (optional)
--
-- These entries have the following purpose:
-- panel.id       string    the internal name of the panel
-- panel.name     string    the external, public name of the panel
-- panel:init()             one-time initialization before the first draw()
-- panel:draw(imgui)        draw the panel
-- panel:draw_menu(imgui)   draw a custom menu at the end of the menubar
-- panel:configure(config)  set or update any configuration
--
-- panel:configure *should* return the current config object, but this is not
-- strictly required.
--
-- Panels are allowed to have whatever else they desire in their panel table.
--]]

--[[ TODO:
-- Save current panel in game Globals
-- Scrollable output text
--]]

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("mods/kae_test/config.lua")

Panel = {
    initialized = false,
    id_current = nil,   -- ID of the "current" panel
    PANELS = { },       -- Table of panel IDs to panel instances

    debugging = false,  -- true if debugging is active/enabled
    lines = {},         -- lines displayed below the panel
}

Panel.SAVE_KEY = "kae_test.panel"

-- Built-in panels
PANELS_NATIVE = {
    dofile_once("mods/kae_test/files/panels/eval.lua"),
    dofile_once("mods/kae_test/files/panels/summon.lua"),
    dofile_once("mods/kae_test/files/panels/info.lua"),
    --dofile_once("mods/kae_test/files/panels_old/progress.lua"),
}

-- Create the panel subsystem. Must be called first, before any other
-- functions are called.
function Panel:new()
    local this = {}
    setmetatable(this, self)
    self.__index = self

    for _, pobj in ipairs(PANELS_NATIVE) do
        self:add(pobj)
    end

    self.debugging = conf_get(CONF.DEBUG)

    return this
end

-- Add a new panel
function Panel:add(panel)
    local pobj = { host = {} }
    setmetatable(pobj, { __index = panel })
    setmetatable(pobj.host, { __index = self })

    if not panel.id then error("panel missing id") end
    if not panel.draw then error("panel " .. panel.id .. " missing draw") end
    pobj.name = panel.name or panel.id
    pobj.init = panel.init or function() end
    pobj.configure = panel.configure or function(config) end

    self.PANELS[panel.id] = pobj

    if panel.init == nil then
        panel.init = function() end
    end
    if panel.configure == nil then
        panel.configure = function() end
    end
    setmetatable(panel, { __index = panel })
    self.PANELS[panel.id] = panel
end

-- Initialize the panel subsystem
-- Must be called after Panel:new()
function Panel:init(env)
    for pid, pobj in pairs(self.PANELS) do
        local res, val = pcall(function() pobj:init(env, self) end)
        if not res then GamePrint(val) end
    end
    local curr_panel = ModSettingGet(Panel.SAVE_KEY)
    if self:is(curr_panel) then
        self:d(("curr := %s (from %s)"):format(curr_panel, Panel.SAVE_KEY))
        self.id_current = curr_panel
    end

    self.initialized = true
end

-- Add a debug line (if debugging is enabled)
function Panel:d(msg)
    if self.debugging then
        table.insert(self.lines, ("DBG: %s"):format(msg))
    end
end

-- Add a debug line unless it already exists
-- Returns true if the insert succeeded, false otherwise
function Panel:d_unique(msg)
    for _, message in ipairs(self.lines) do
        if message == msg then
            return false
        end
    end
    self:d(msg)
    return true
end

-- Add a line
function Panel:p(msg)
    table.insert(self.lines, msg)
end

-- Prepend a line
function Panel:prepend(msg)
    table.insert(self.lines, 1, msg)
end

-- Clear the text. Operates by reference just in case a panel has a
-- direct reference to self.lines.
function Panel:text_clear()
    while #self.lines > 0 do
        table.remove(self.lines, 1)
    end
end

function Panel:is(pid) return self.PANELS[pid] ~= nil end

function Panel:get(pid)
    if self:is(pid) then
        return self.PANELS[pid]
    end
    return nil
end

function Panel:set(pid)
    if self:is(pid) then
        self.id_current = pid
        --ModSettingSetNextValue(Panel.SAVE_KEY, pid, false)
    end
end

function Panel:reset()
    self.id_current = nil
end

function Panel:current()
    if self.id_current ~= nil then
        return self:get(self.id_current)
    end
    return nil
end

function Panel:build_menu(imgui)
    local current = self:current()

    if imgui.BeginMenu("Panel") then
        if self.debugging then
            if imgui.MenuItem("Disable Debugging") then
                self.debugging = false
                conf_set(CONF.DEBUG, self.debugging)
            end
        else
            if imgui.MenuItem("Enable Debugging") then
                self.debugging = true
                conf_set(CONF.DEBUG, self.debugging)
            end
        end

        if imgui.MenuItem("Copy") then
            local all_lines = ""
            for _, line in ipairs(self.lines) do
                all_lines = all_lines .. line .. "\r\n"
            end
            imgui.SetClipboardText(all_lines)
        end

        if imgui.MenuItem("Clear") then
            self.lines = {}
        end

        if imgui.MenuItem("Close") then
            conf_set(CONF.ENABLE, false)
        end

        imgui.Separator()

        for pid, pobj in pairs(self.PANELS) do
            local mstr = pobj.name
            if pid == self.id_current then
                mstr = mstr .. " [*]"
            end
            if imgui.MenuItem(mstr) then
                self:set(pid)
            end
        end

        imgui.Separator()

        if current ~= nil then
            if imgui.MenuItem("Return") then
                self:reset()
            end
        end

        imgui.EndMenu()
    end

    if current ~= nil then
        if current.draw_menu ~= nil then
            current:draw_menu(imgui)
        end
    end

end

function Panel:draw(imgui)

    local current = self:current()
    if current ~= nil then
        current:draw(imgui)
    end

    for _, line in ipairs(self.lines) do
        imgui.Text(line)
    end
end

return Panel

-- vim: set ts=4 sts=4 sw=4 tw=79:
