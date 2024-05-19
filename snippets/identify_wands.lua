
-- Update all unnamed held wands to display their internal names

local px, py = EntityGetTransform(player)
local wands = EntityGetInRadiusWithTag(px, py, 1, "wand")
for _, wand in ipairs(wands) do
    local icomp = EntityGetFirstComponentIncludingDisabled(wand, "ItemComponent")
    local acomp = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
    local iname = ComponentGetValue2(icomp, "item_name")
    local aname = ComponentGetValue2(acomp, "ui_name")
    local show_name = ComponentGetValue2(icomp, "always_use_item_name_in_ui")
    if not show_name then
        ComponentSetValue2(icomp, "always_use_item_name_in_ui", true)
    end
    local new_name = ""
    if iname == "" and aname ~= "" then
        new_name = aname
    elseif iname ~= "" and aname ~= "" and iname ~= aname then
        if not iname:find(aname) and not aname:find(iname) then
            new_name = ("%s (%s)"):format(aname, iname)
        end
    end
    if new_name ~= "" then
        print(wand, new_name)
        ComponentSetValue2(icomp, "item_name", new_name)
    end
end
