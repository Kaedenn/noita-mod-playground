--[[
The "Radar" Panel: Display information about nearby things
--]]

RadarPanel = {
    id = "radar",
    name = "Radar",
    config = {
        range = math.huge,
        rare_materials = {
            "magic_liquid_hp_regeneration",
            "urine",
            "creepy_liquid",
        },
    },
    env = nil,
    host = nil,
    funcs = {
        --ModTextFileGetContent = ModTextFileGetContent,
    },
}

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

--[[ Get the display string for the entity ]]
local function _get_name(entity)
    local comps = EntityGetComponentIncludingDisabled(entity, "ItemComponent")
    if comps and #comps > 0 then
        for _, comp in ipairs(comps) do
            local uiname = ComponentGetValue2(comp, "item_name")
            if uiname ~= "" then
                return uiname
            end
        end
    end
    local name = EntityGetName(entity)
    local path = EntityGetFilename(entity)
    -- TODO: handle other entities
    path = path:gsub("data/entities/items/pickup/([%a_]+).xml", "%1")
    if name ~= "" then return ("%s [%s]"):format(name, path) end
    return path
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

--[[ Filter out entities that are children of the player or too far away ]]
function RadarPanel:_filter_entries(entries)
    local results = {}
    for _, entry in ipairs(entries) do
        local entity = entry[1]
        if not _is_child_of(entity, nil) then
            local distance = _distance_from(entity, nil)
            if distance <= self.config.range then
                table.insert(results, entry)
            end
        end
    end
    return results
end

--[[ Get all non-held items within conf.range ]]
function RadarPanel:_get_items()
    return self:_filter_entries(_get_with_tags({"item_pickup"}))
end

--[[ Locate any flasks/pouches containing rare materials ]]
function RadarPanel:_get_rare_containers()
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

function RadarPanel:init(environ, host)
    self.env = environ or {}
    self.host = host or {}

    setmetatable(self, { __index = environ or _G })
    return self
end

function RadarPanel:draw_menu(imgui)
    if imgui.BeginMenu(self.name) then
        imgui.EndMenu()
    end
end

function RadarPanel:draw(imgui)
    self.host:text_clear()

    for _, entry in ipairs(_aggregate(self:_get_items())) do
        local name = entry[1]
        local entities = entry[2]
        self.host:p(("%dx %s"):format(#entities, GameTextGet(name)))

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

function RadarPanel:configure(config)
    for key, value in pairs(config) do
        self.config[key] = value
    end
end

return RadarPanel

-- vim: set ts=4 sts=4 sw=4:
