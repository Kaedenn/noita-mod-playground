--[[

The "Info" Panel: Display interesting information

TODO: Only display the primary biome of a biome group
--]]

-- luacheck: globals nxml

dofile("mods/kae_test/files/imguiutil.lua")

InfoPanel = {
    id = "info",
    name = "Info",
    config = {
        range = math.huge,
        rare_materials = {
            "magic_liquid_hp_regeneration",
            "urine",
            "creepy_liquid",
        },
        rare_entities = {

        },
    },
    env = {},
    host = nil,
    funcs = {
        ModTextFileGetContent = ModTextFileGetContent,
    },
}

local function _biome_is_default(biome_name, modifier)
    if modifier == nil or modifier == "" then return true end
    local default_map = {
        ["alchemist_secret"] = "$biomemodifierdesc_fog_of_war_clear_at_player",
        ["desert"] = "$biomemodifierdesc_hot",
        ["fungicave"] = "$biomemodifierdesc_moist",
        ["lavalake"] = "$biomemodifierdesc_hot",
        ["mountain_floating_island"] = "$biomemodifierdesc_freezing",
        ["mountain_top"] = "$biomemodifierdesc_freezing",
        ["pyramid_entrance"] = "$biomemodifierdesc_hot",
        ["pyramid_left"] = "$biomemodifierdesc_hot",
        ["pyramid_right"] = "$biomemodifierdesc_hot",
        ["pyramid_top"] = "$biomemodifierdesc_hot",
        ["rainforest"] = "$biomemodifierdesc_fungal",
        ["rainforest_open"] = "$biomemodifierdesc_fungal",
        ["wandcave"] = "$biomemodifierdesc_fog_of_war_clear_at_player",
        ["watercave"] = "$biomemodifierdesc_moist",
        ["winter"] = "$biomemodifierdesc_freezing",
        ["winter_caves"] = "$biomemodifierdesc_freezing",
        ["wizardcave"] = "$biomemodifierdesc_fog_of_war_clear_at_player",
    }
    if default_map[biome_name] == modifier then
        return true
    end
    return false
end

--[[ True if entity is a child of root ]]
local function _is_child_of(entity, root)
    if root == nil then root = get_players()[1] end
    local seen = {} -- To protect against cycles
    local curr = EntityGetParent(entity)
    if curr == root then return true end
    while curr ~= 0 and not seen[curr] do
        if curr == root then return true end
        seen[curr] = EntityGetParent(curr)
        if curr == seen[curr] then return false end
        curr = seen[curr]
    end
end

--[[ True if the entity is an item ]]
local function _entity_is_item(entity)
    return EntityHasTag(entity, "item_pickup")
end

--[[ True if the entity is an enemy ]]
local function _entity_is_enemy(entity)
    return EntityHasTag(entity, "enemy")
end

--[[ Get the display string for an item entity ]]
local function _item_get_name(entity)
    local name = EntityGetName(entity)
    local comps = EntityGetComponentIncludingDisabled(entity, "ItemComponent") or {}
    for _, comp in ipairs(comps) do
        local uiname = ComponentGetValue2(comp, "item_name")
        if uiname ~= "" then
            name = uiname
            break
        end
    end

    local path = EntityGetFilename(entity)
    if path:match("chest_random_super.xml") then
        return GameTextGet("$item_chest_treasure_super")
    end

    if name ~= "" and name:match("^[$][%a]+_[%a%d_]+$") then
        locname = GameTextGet(name)
        name = name:gsub("^[$][%a]+_", "") -- strip "$item_" prefix
        return ("%s [%s]"):format(locname, name)
    end

    if name ~= "" then return name end
    return nil
end

--[[ Get the display string for an enemy entity ]]
local function _enemy_get_name(entity)
    local name = EntityGetName(entity)
    local locname = name
    if name ~= "" and name:match("^[$][%a]+_[%a%d_]+$") then
        locname = GameTextGet(name)
        if locname == "" then locname = name end
        name = name:gsub("^[$][%a]+_", "") -- strip "$animal_" prefix
    end

    local path = EntityGetFilename(entity)
    local label = path:gsub("^[%a_/]+/([%a%d_]+).xml", "%1")
    if path:match("data/entities/animals/([%a_]+)/([%a%d_]+).xml") then
        label = path:gsub("data/entities/animals/([%a_]+)/([%a%d_]+).xml",
            function(dirname, basename)
                if dirname == basename then
                    return dirname
                end
                return ("%s (%s)"):format(basename, dirname)
            end)
    elseif path:match("data/entities/animals/([%a%d_]+).xml") then
        label = path:gsub("data/entities/animals/([%a%d_]+).xml", "%1")
    end
    if name == "" then
        locname = label
        name = label
    end

    local result = name
    if locname ~= name and label ~= name then
        result = ("%s [%s] [%s]"):format(locname, name, label)
    elseif locname ~= name then
        result = ("%s [%s]"):format(locname, name)
    elseif label ~= name then
        result = ("%s [%s]"):format(name, label)
    end
    return result
end

--[[ Get the display string for the entity ]]
local function _get_name(entity)
    if _entity_is_item(entity) then
        return _item_get_name(entity)
    end

    if _entity_is_enemy(entity) then
        return _enemy_get_name(entity)
    end

    -- Default behavior for "other" entity types
    local name = EntityGetName(entity)
    local path = EntityGetFilename(entity)
    if path:match("data/entities/items/pickup/([%a_]+).xml") then
        path = path:gsub("data/entities/items/pickup/([%a_]+).xml", "%1")
    elseif path:match("data/entities/animals/([%a_]+)/([%a_]+).xml") then
        path = path:gsub("data/entities/animals/([%a_]+)/([%a_]+).xml", "%2 (%1)")
    elseif path:match("data/entities/animals/([%a_]+).xml") then
        path = path:gsub("data/entities/animals/([%a_]+).xml", "%1")
    end
    if name ~= "" then return ("%s [%s]"):format(name, path) end
    return path
end

--[[ Get both the current and max health of the entity ]]
local function _get_health(entity)
    local comps = EntityGetComponentIncludingDisabled(entity, "DamageModelComponent") or {}
    if #comps == 0 then return nil end
    -- FIXME: don't hard-code 25
    local health = ComponentGetValue2(comps[1], "hp") * 25
    local maxhealth = ComponentGetValue2(comps[1], "max_hp") * 25
    return {health, maxhealth}
end

--[[ Get all entities having one of the given tags ]]
local function _get_with_tags(tags)
    local entities = {}
    for _, tag in ipairs(tags) do
        for _, entity in ipairs(EntityGetWithTag(tag)) do
            entities[entity] = _get_name(entity)
        end
    end
    local results = {}
    for entid, name in pairs(entities) do
        table.insert(results, {entid, name})
    end
    return results
end

--[[ Return the distance (in pixels) between two entities
-- Reference defaults to the player if nil ]]
local function _distance_from(entity, reference)
    if reference == nil then reference = get_players()[1] end
    local rx, ry = EntityGetTransform(reference)
    local ex, ey = EntityGetTransform(entity)
    return math.sqrt(math.pow(rx-ex, 2) + math.pow(ry-ey, 2))
end

--[[ Collect {id, name} pairs into {name, {id...}} sets ]]
local function _aggregate(entries)
    local byname = {}
    for _, entry in ipairs(entries) do
        local entity = entry[1]
        local name = entry[2]
        if not byname[name] then
            byname[name] = {}
        end
        table.insert(byname[name], entity)
    end
    local results = {}
    for name, entities in pairs(byname) do
        table.insert(results, {name, entities})
    end
    table.sort(results, function(left, right)
        local lname, rname = left[1], right[1]
        return lname < rname
    end)
    return results
end

--[[ Get the contents of a given container (flask/pouch) ]]
function _container_get_contents(entity)
    local results = {}
    local comps = EntityGetComponentIncludingDisabled(entity, "MaterialInventoryComponent")
    if not comps or #comps == 0 then return {} end
    local comp = comps[1]
    if not comp or comp == 0 then return {} end
    for idx, count in ipairs(ComponentGetValue2(comp, "count_per_material_type")) do
        if count ~= 0 then
            local matid = idx - 1
            local matname = CellFactory_GetName(matid)
            --local uiname = CellFactory_GetUIName(matid)
            --local matuiname = GameTextGetTranslatedOrNot(uiname)
            results[matname] = count
        end
    end
    return results
end

--[[ Get biome information (name, path, modifier) for each biome ]]
function InfoPanel:_get_biome_data()
    local biome_xml = nxml.parse(self.funcs.ModTextFileGetContent("data/biome/_biomes_all.xml"))
    local biomes = {}
    for _, bdef in ipairs(biome_xml.children) do
        local biome_path = bdef.attr.biome_filename
        local biome_name = biome_path:match("^data/biome/(.*).xml$")
        local modifier = BiomeGetValue(biome_path, "mModifierUIDescription")
        if not _biome_is_default(biome_name, modifier) then
            biomes[biome_name] = {
                name = biome_name, -- TODO: reliably determine localized name
                path = biome_path,
                modifier = modifier,
                text = GameTextGet(modifier),
            }
        end
    end
    return biomes
end

--[[ Filter out entities that are children of the player or too far away ]]
function InfoPanel:_filter_entries(entries)
    local results = {}
    for _, entry in ipairs(entries) do
        local entity = entry[1]
        local name = entry[2]
        if name:match("^mods/") == nil then
            if not _is_child_of(entity, nil) then
                local distance = _distance_from(entity, nil)
                if distance <= self.config.range then
                    table.insert(results, entry)
                end
            end
        end
    end
    return results
end

--[[ Get all non-held items within conf.range ]]
function InfoPanel:_get_items()
    return self:_filter_entries(_get_with_tags({"item_pickup"}))
end

--[[ Locate any flasks/pouches containing rare materials ]]
function InfoPanel:_get_rare_containers()
    local containers = {}
    for _, item in ipairs(self:_filter_entries(_get_with_tags({"item_pickup"}))) do
        local entity = item[1]
        local name = item[2]
        local contents = _container_get_contents(entity)
        local rare_mats = {}
        for _, material in ipairs(self.config.rare_materials) do
            if contents[material] and contents[material] > 0 then
                table.insert(rare_mats, material)
            end
        end
        if #rare_mats > 0 then
            table.insert(containers, {
                entity = entity,
                name = name,
                contents = contents,
                rare_contents = rare_mats,
            })
        end
    end
    return containers
end

--[[ Count the nearby enemies ]]
function InfoPanel:_get_enemies()
    return self:_filter_entries(_get_with_tags({"enemy"}))
end

function InfoPanel:_get_rare_enemies() -- TODO
    local enemies = {}
    for _, enemy in ipairs(self:_get_enemies()) do
        local entity = enemy[1]
        local name = enemy[2]
        
    end
    return enemies
end

function InfoPanel:init(environ, host)
    self.env = environ or {}
    self.host = host or {}

    for _, varname in ipairs({
        "biome_list",
        "item_list",
        "enemy_list",
        "onscreen",
        "show_health",
    }) do
        if self.env[varname] == nil then
            local save_value = self.host:get_var(self.id, varname, "true")
            if save_value == "true" or save_value == "false" then
                self.env[varname] = (save_value == "true")
            else
                self.env[varname] = true
            end
        end
    end

    self.biomes = self:_get_biome_data()
    self.gui = GuiCreate()

    setmetatable(self, { __index = function(tbl, key)
        return rawget(tbl, key)
    end })
    return self
end

function InfoPanel:draw_menu(imgui)
    if imgui.BeginMenu(self.name) then
        imgui.EndMenu()
    end
end

function InfoPanel:_draw_checkboxes(imgui)
    local entries = {
        {"Biomes", "biome_list"},
        {"Items", "item_list"},
        {"Enemies", "enemy_list"},
        {"On-screen", "onscreen"},
        {"Health bars", "show_health"},
    }

    for idx, bpair in ipairs(entries) do
        if idx > 1 then imgui.SameLine() end
        imgui.SetNextItemWidth(100)
        local name = bpair[1]
        local varname = bpair[2]
        local ret, value = imgui.Checkbox(name, self.env[varname])
        if ret then
            self.env[varname] = value
            self.host:set_var(self.id, varname, "1")
        end
    end
end

function InfoPanel:draw(imgui)
    self.host:text_clear()

    self:_draw_checkboxes(imgui)

    --[[if self.env.onscreen then
        if not self.gui then self.gui = GuiCreate() end
        GuiLayoutBeginVertical(self.gui, 1, 10)
    end]]

    if self.env.biome_list then
        --[[ Print all non-default biome modifiers ]]
        for bname, bdata in pairs(self.biomes) do
            self.host:p(("%s: %s"):format(bdata.name, bdata.text))
        end
        --[[ Debugging: print the unlocalized strings from above ]]
        for bname, bdata in pairs(self.biomes) do
            self.host:d(("%s: %s"):format(bname, bdata.modifier))
        end
    end

    if self.env.item_list then
        self.host:p(self.host.separator)
        for _, entry in ipairs(_aggregate(self:_get_items())) do
            local name = entry[1]
            local entities = entry[2]
            local line = ("%dx %s"):format(#entities, name)
            self.host:p(line)
            --if self.env.onscreen then GuiText(self.gui, 0, 0, text) end

            for _, entity in ipairs(entities) do
                local ex, ey = EntityGetTransform(entity)
                self.host:d(("Entity %s %d at {%d,%d}"):format(name, entity, ex, ey))
            end
        end

        for _, entity in ipairs(self:_get_rare_containers()) do
            self.host:p(("%s with %s detected nearby!!"):format(
                entity.name, table.concat(entity.rare_contents, ", ")))
            local ex, ey = EntityGetTransform(entity.entity)
            self.host:d(("Entity %s %d at {%d,%d}"):format(
                entity.name, entity.entity, ex, ey))
        end
    end

    if self.env.enemy_list then
        self.host:p(self.host.separator)
        for _, entry in ipairs(_aggregate(self:_get_enemies())) do
            local name = entry[1]
            local entities = entry[2]
            self.host:p(("%dx %s"):format(#entities, name))
        end

        for _, entity in ipairs(self:_get_rare_enemies()) do
            self.host:p(("%s detected nearby!!"):format(entity.name))
            local ex, ey = EntityGetTransform(entity.entity)
            self.host:d(("Entity %s %d at {%d,%d}"):format(
                entity.name, entity.entity, ex, ey))
        end
    end

    if self.env.show_health then
        self.host:p(self.host.separator)
        for _, entity in ipairs(self:_get_enemies()) do
            local health = _get_health(entity)
            if health ~= nil then
                local curr, max = health[1], health[2]
                -- TODO: draw "curr/max" near entity
            end
        end
    end

    --[[if self.env.onscreen then
        GuiLayoutEnd(self.gui)
    end]]
end

function InfoPanel:configure(config)
    for key, value in pairs(config) do
        self.config[key] = value
    end
end

return InfoPanel

-- vim: set ts=4 sts=4 sw=4:
