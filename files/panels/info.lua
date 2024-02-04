--[[

The "Info" Panel: Display interesting information

TODO: Only display the primary biome of a biome group
--]]

dofile("mods/kae_test/files/imguiutil.lua")

InfoPanel = {
    id = "info",
    name = "Info",
    config = {
    },
    env = nil,
    host = nil,
    funcs = {
        ModTextFileGetContent = ModTextFileGetContent,
    },
}

function _biome_is_default(biome_name, modifier)
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

function InfoPanel:_get_biome_data()
    local biome_xml = nxml.parse(self.funcs.ModTextFileGetContent("data/biome/_biomes_all.xml"))
    local biomes = {}
    for _, bdef in ipairs(biome_xml.children) do
        local biome_path = bdef.attr.biome_filename
        local biome_name = biome_path:match("^data/biome/(.*).xml$")
        local modifier = BiomeGetValue(biome_path, "mModifierUIDescription")
        if not _biome_is_default(biome_name, modifier) then
            biomes[biome_name] = {
                path = biome_path,
                modifier = modifier,
                text = GameTextGet(modifier),
            }
        end
    end
    return biomes
end

function InfoPanel:init(environ, host)
    self.env = environ or {}
    self.host = host or {}

    self.biomes = self:_get_biome_data()

    setmetatable(self, { __index = environ or _G })
    return self
end

function InfoPanel:draw_menu(imgui)
    if imgui.BeginMenu(self.name) then
        imgui.EndMenu()
    end
end

function InfoPanel:draw(imgui)
    self.host:text_clear()
    for bname, bdata in pairs(self.biomes) do
        self.host:p(("%s: %s"):format(bname, bdata.text))
    end
    for bname, bdata in pairs(self.biomes) do
        self.host:d(("%s: %s"):format(bname, bdata.modifier))
    end
end

function InfoPanel:configure(config)
    for key, value in pairs(config) do
        self.config[key] = value
    end
end

return InfoPanel

-- vim: set ts=4 sts=4 sw=4:
