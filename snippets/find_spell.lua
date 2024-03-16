

player = get_players()[1]
if self and self.host and self.host.text_clear then self.host:text_clear() end

function card_get_spell(card)
  local action = EntityGetComponentIncludingDisabled(card, "ItemActionComponent")
  if #action == 1 then
    return ComponentGetValue2(action[1], "action_id")
  end
  return nil
end

function wand_get_spells(wand)
  local cards = EntityGetAllChildren(wand) or {}
  local spells = {}
  for _, card in ipairs(cards) do
    local spell = card_get_spell(card)
    if spell ~= nil then
      table.insert(spells, spell)
    end
  end
  return spells
end

function is_held_thing(entity)
  local entid = EntityGetParent(entity)
  local seen = {}
  while entid ~= 0 and not seen[entid] do
    seen[entid] = EntityGetParent(entid)
    if entid == player then return true end
    if entid == seen[entid] then return false end
    entid = seen[entid]
  end
  return false
end

function print_entity_position(entity, message)
  local px, py = EntityGetTransform(get_players()[1])
  local wx, wy = EntityGetTransform(entity)
  if wx == nil and wy == nil then wx, wy = px, py end
  local dx, dy = wx-px, wy-py
  local dist = math.sqrt(dx*dx + dy*dy)
  if wx ~= 0 and wy ~= 0 then
    if not is_held_thing(entity) then
      print(("Entity %s at (%d, %d) (%d,%d; %d pixels away) %s"):format(
        tostring(entity), wx, wy, dx, dy, dist, message or "found"))
    end
  end
end

function search_for_spell_list(spell_list)
  print(("Searching for %d spells nearby..."):format(#spell_list))

  --[[ Look for wands ]]
  local spell_table = {}
  for _, entry in ipairs(spell_list) do spell_table[entry] = true end
  for widx, wand in ipairs(EntityGetWithTag("wand")) do
    local print_wand = false
    local found_spells = {}
    for cidx, spell in ipairs(wand_get_spells(wand)) do
      if spell_table[spell] then
        found_spells[spell] = (found_spells[spell] or 0) + 1
        print_wand = true
      end
    end
    local message = ""
    for spell, count in pairs(found_spells) do
      if message ~= "" then message = message .. " " end
      local part = spell
      if count > 1 then
        part = ("%dx %s"):format(count, spell)
      end
      message = message .. part
    end
    if print_wand then
      print_entity_position(wand, "contains " .. message)
    end
  end

  --[[ Look for lone spell cards (eg. Holy Mountain) ]]
  for cidx, card in ipairs(EntityGetWithTag("card_action")) do
    if not is_held_thing(card) then
      local spell = card_get_spell(card)
      if spell ~= nil and spell_table[spell] then
        print_entity_position(card, spell)
      end
    end
  end
end

search_for_spell_list({
"REGENERATION_FIELD",
"MANA_REDUCE",
"TELEPORT_PROJECTILE",
"TELEPORT_PROJECTILE_SHORT",
--"EXPLOSION_TINY",
--"HITFX_CRITICAL_WATER",
--"MATERIAL_WATER",
})

