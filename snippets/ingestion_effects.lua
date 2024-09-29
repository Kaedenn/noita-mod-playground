
dofile("data/scripts/lib/utilities.lua")
function get_ingestion_effect_duration(material_name)
    local mid = CellFactory_GetType(material_name)

    local player = get_players()[1]
    local comp = EntityGetFirstComponentIncludingDisabled(player, "StatusEffectDataComponent")
    if comp == 0 then error("Player lacks StatusEffectDataComponent") end

    local times = ComponentGetValue2(comp, "ingestion_effects")
    local causes = ComponentGetValue2(comp, "ingestion_effect_causes")
    local effect_idx = nil
    for idx, cause in ipairs(causes) do
        if cause == mid then
            effect_idx = idx
            break
        end
    end
    if effect_idx == nil then
        error(("No effect caused by %s"):format(material_name))
    end
    local effect_time = times[effect_idx]
    local effect_cause = causes[effect_idx]
    print(("Effect %s [caused by %s] has %f seconds remaining"):format(
        effect_idx, material_name, effect_time))
    return effect_time
end
print(get_ingestion_effect_duration("meat_polymorph_protection"))

-- vim: set ts=4 sts=4 sw=4:
