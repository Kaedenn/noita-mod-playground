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
-- panel:configure(table)  (optional)
--
-- These entries have the following purpose:
-- panel.id       string    the internal name of the panel
-- panel.name     string    the external, public name of the panel
-- panel:init()             one-time initialization before the first draw()
-- panel:draw(imgui)        draw the panel
-- panel:configure(config)  set or update any configuration
--
-- panel:configure *should* return the current config object, but this is not
-- strictly required.
--
-- Panels are allowed to have whatever else they desire in their panel table.
--]]

dofile_once("data/scripts/lib/utilities.lua")

Panel = {
    id_default = nil,   -- ID of the "default" panel
    id_current = nil,   -- ID of the "current" panel
    PANELS = { },       -- Table of panel IDs to panel instances

    debug = false,
    debug_lines = {},
}

-- Built-in panels
PANELS_NATIVE = {
    --dofile_once("mods/kae_test/files/panels/eval.lua"),
    --dofile_once("mods/kae_test/files/panels/progress.lua"),
    --dofile_once("mods/kae_test/files/panels/summon.lua"),
}

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

    self.PANELS[pid] = pobj

    if panel.init == nil then
        panel.init = function() end
    end
    if panel.configure == nil then
        panel.configure = function() end
    end
    setmetatable(panel, { __index = panel })
    self.PANELS[pid] = panel
end

function Panel:init()
    local this = {}
    setmetatable(this, self)
    self.__index = self

    for _, pobj in ipairs(PANELS_NATIVE) do
        self:add(pobj)
        if self.id_default == nil then
            self.id_default = pobj.id
        end
    end

    return this
end

function Panel:is(pid) return self.PANELS[pid] ~= nil end

function Panel:get(pid)
    if self:is(id) then
        return self.PANELS[pid]
    end
    return nil
end

function Panel:set(pid)
    if self:is(id) then
        self.id_current = id
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
    if imgui.BeginMenu("Panel") then
        if imgui.BeginMenu("Logging") then
            local mstr = self.debug and "Disable" or "Enable"
            if imgui.MenuItem(mstr .. " Debugging") then
                self.debug = not self.debug
            end

            if imgui.MenuItem("Clear") then
                self.debug_lines = {}
            end

            if imgui.MenuItem("Close") then
                ModSettingSetNextValue("kae_test.enable", false, false)
            end
            imgui.EndMenu()
        end

        for pid, pobj in pairs(self.PANELS) do
            local mstr = pobj.name
            if pid == self.id_default then
                mstr = mstr .. " [D]"
            end
            if pid == self.id_current then
                mstr = mstr .. " [*]"
            end
            if imgui.MenuItem(mstr) then
                self:set(pid)
            end
        end

        if imgui.MenuItem("Clear") then
            self:reset()
        end

        imgui.EndMenu()
    end
end

function Panel:draw(imgui)
    -- TODO
 
    if self.debug then
        for _, line in ipairs(debug_lines) do
            imgui.Text(line)
        end
    end
end

-- Public: True if a panel exists with the given id
function is_panel(id) return PANELS[id] ~= nil end

-- Public: Get the current panel's id (nil if none)
function get_current_id() return panel_current end

-- Public: Get the current panel object (nil if none)
function get_current_panel()
    local pid = get_current_id()
    if pid ~= nil and is_panel(pid) then
        return PANELS[pid]
    end
    return nil
end

-- Public: Set the current panel to the one with the given id
function set_current_id(id)
    if is_panel(id) then
        panel_current = id
        return true
    end
    return false
end

-- Public: Add a new panel object, handling default and optional values
function add_panel(pdef)
    local panel_id = pdef.id or error("missing 'id' field")
    local panel_name = pdef.name or panel_id
    local panel_init = pdef.init or function() end
    local panel_draw = pdef.draw or error("missing 'draw' field")
    local panel_configure = pdef.configure or function(config) end

    PANELS[panel_id] = {
        id = panel_id,
        name = panel_name,
        init = panel_init,
        draw = panel_draw,
        configure = panel_configure,
        initialized = false,
    }
end

-- Public: Build the panel menu. Assumes BeginMenuBar has already been called.
function build_panel_menu(imgui)
    if imgui.BeginMenu("Panels") then
        for panel_id, panel in pairs(PANELS) do
            if imgui.MenuItem(panel.name or panel_id) then
                set_current_id(panel_id)
            end
        end
        if imgui.MenuItem("Main") then
            panel_current = nil
        end
        imgui.EndMenu()
    end
end

-- Public: Draw the current panel
function draw_panel(imgui, ...)
    local pid = get_current_panel()
    if pid ~= nil and is_panel(pid) then
        pobj = PANELS[pid]
        if not pobj.initialized then
            pobj.init(_G)
        end
        pobj.draw(imgui, _G)
    end
end

return Panel

-- vim: set ts=4 sts=4 sw=4 tw=79:
