self.host:text_clear()
matutil = dofile_once("mods/component-explorer/utils/matutil.lua")
player_x, player_y = EntityGetTransform(get_players()[1])
function print_contents(entity)
  local ex, ey = EntityGetTransform(entity)
  if not ex or not ey then return end
  local dist = math.sqrt(math.pow(ex - player_x, 2) + math.pow(ey - player_y, 2))
  local comps = EntityGetComponentIncludingDisabled(entity, "MaterialInventoryComponent")
  if not comps or #comps == 0 then return end
  local comp = comps[1]
  if not comp or comp == 0 then return end
  for material_id_, count in ipairs(ComponentGetValue2(comp, "count_per_material_type")) do
    if count ~= 0 then
      local material_id = material_id_ - 1
      local matname = matutil.material_name(material_id)
      local matuiname = GameTextGetTranslatedOrNot(CellFactory_GetUIName(material_id))
      print(("%d {%d,%d; %d) has %d of %s (%s) [%d]"):format(entity, ex, ey, dist, count, matuiname, matname, material_id))
    end
  end
end
for _, entity in ipairs(EntityGetWithTag("potion")) do
  print_contents(entity)
end
