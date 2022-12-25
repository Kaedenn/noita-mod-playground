--[[
-- Panel GUI System
--
-- This script implements "panels", which are separate user-defined GUI layouts
-- selected by menu.
--
-- Panels are tables with the following entries:
-- panel.id = "string"     (required)
-- panel.name = "string"   (optional; defaults to panel.id)
-- panel.init()            (optional)
-- panel.draw(imgui)       (required)
-- panel.configure(table)  (optional)
--
-- These entries have the following purpose:
-- panel.id       string    the internal name of the panel
-- panel.name     string    the external, public name of the panel
-- panel.init()             one-time initialization before the first draw()
-- panel.draw(imgui)        draw the panel
-- panel.configure(config)  set or update any configuration
--
-- panel.configure *should* return the current config object, but this is not
-- strictly required.
--
-- Panels are allowed to have whatever else they desire in their panel table.
--]]

dofile_once("data/scripts/lib/utilities.lua")

-- Built-in panels
PANELS_NATIVE = {
    dofile_once("mods/kae_test/files/panels/eval.lua"),
    dofile_once("mods/kae_test/files/panels/progress.lua"),
    dofile_once("mods/kae_test/files/panels/summon.lua"),
}

-- Table of all known panels
PANELS = {}

-- The default panel, specified by id
local panel_default = nil

-- The current panel, specified by id
local panel_current = nil

local function _init_panels()
    local index, panel
    for index, panel in ipairs(PANELS_NATIVE) do
        PANELS[panel.id] = panel
        if panel_default == nil then
            panel_default = panel.id
        end
    end
end
_init_panels()

-- Public: True if a panel exists with the given id
function is_panel(id) return PANELS[id] ~= nil end

-- Public: Get the current panel's id (nil if none)
function get_current_panel() return panel_current end

-- Public: Get the current panel object (nil if none)
function get_current_pobject()
    local pid = get_current_panel()
    if pid ~= nil and is_panel(pid) then
        return PANELS[pid]
    end
    return nil
end

-- Public: Set the current panel to the one with the given id
function set_current_panel(id)
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
                set_current_panel(panel_id)
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

return {
    PANELS = PANELS,
    is_panel = is_panel,
    get_current_panel = get_current_panel,
    set_current_panel = set_current_panel,
    add_panel = add_panel,
    build_panel_menu = build_panel_menu,
    draw_panel = draw_panel,
}

-- vim: set ts=4 sts=4 sw=4 tw=79:
