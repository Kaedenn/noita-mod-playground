--[[
-- The "Summon" Panel: Summon items, perks, entities, and more.
--
-- Planned features:
--  Pixel adjust to spawn entities above/blow/etc player
--  Free-form input to spawn modded objects
--  Flask/pouch toggle
--  Slider with number input to set container fill level
--  ??? Multi-content containers?
--]]

dofile_once("data/scripts/lib/utilities.lua")
S_ENTITY = dofile("mods/kae_test/files/generated/entities.lua")

SummonPanel = {
    id = "summon",
    name = "Summon",
    config = {
        mode = "entity",
        container = "flask",    -- either "flask" or "pouch"
    },
    env = {},
    host = {},

    MODES = {
        "entity",
        "container",
        "item",
        "perk",
    },

    CHOICES = {},
}

--[[ Initialize this panel ]]
function SummonPanel:init(environ, host)
    self.env = environ or {}
    self.host = host or {}
    setmetatable(self, { __index = environ or _G })

    if type(S_ENTITY) ~= "table" then
        error("Failed to load entity data")
    end

    for ents_kind, ents in pairs(S_ENTITY) do
        if self.CHOICES[ents_kind] == nil then
            self.CHOICES[ents_kind] = {}
        end
        for ent_name, ent in ipairs(ents) do
            local tags = {}
            for tag in ent.tags:gmatch("[^,]+") do
                table.insert(tags, tag)
            end
        end
    end

    return self
end

--[[ Find all summon-able things satisfying the given rules
--
-- Must be invoked like self:filter{kind="...", tag="..." or tags={...}, ...}
--
--]]
function SummonPanel:filter(rules)
    local kind = rules.kind or nil
    local tags = rules.tags or {}
    if rules.tag then
        table.insert(tags, rules.tag)
    end

    -- TODO: any other criteria?

    -- TODO: filter down the choices and return the new table

end

--[[ Convenience: display a debugging message in the host ]]
function SummonPanel:d(message)
    self.host:d(message)
end

--[[ Convenience: true if debugging is enabled, false otherwise ]]
function SummonPanel:debugging()
    return self.host.debugging
end

--[[ True if the given mode is valid, false otherwise ]]
function SummonPanel:_is_mode(mode)
    for _, value in ipairs(SummonPanel.MODES) do
        if value == mode then
            return true
        end
    end
    return false
end

--[[ Summon a thing; for_mode is optional and defaults to self.config.mode ]]
function SummonPanel:summon(thing, for_mode)
    local mode = for_mode or self.config.mode
end

--[[ Public: draw any menu(s) this panel desires ]]
function SummonPanel:draw_menu(imgui)
    if imgui.BeginMenu(self.name) then
        for _, mode in ipairs(SummonPanel.MODES) do
            local label = mode:sub(1, 1):upper() .. mode:sub(2)
            if imgui.MenuItem("Summon " .. label) then
                self.config.mode = mode
                self:d("Set mode to " .. mode)
            end
        end
        imgui.EndMenu()
    end
end

--[[ Public: draw the panel itself ]]
function SummonPanel:draw(imgui)
end

--[[ Public: configure this panel ]]
function SummonPanel:configure(config)
    for key, value in pairs(config) do
        if key == "mode" and self:_is_mode(value) then
            self.config.mode = value
        end
    end
end

return SummonPanel

-- vim: set ts=4 sts=4 sw=4:
