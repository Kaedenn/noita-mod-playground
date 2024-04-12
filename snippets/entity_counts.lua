self.host:text_clear()

function match_any(str, parts)
  for _, part in ipairs(parts or {}) do
    if #part == 0 then
      if #str == 0 then
        return true
      end
    else
      local spos, epos = str:find(part)
      if spos ~= nil and epos ~= nil and spos >= 0 and epos <= #str then
        return true
      end
    end
  end
  return false
end

function should_omit_entity(entity, omit_rules)
  local omit_tags = omit_rules and omit_rules.tags or {}
  local omit_names = omit_rules and omit_rules.names or {}
  local omit_paths = omit_rules and omit_rules.paths or {}
  local tags = EntityGetTags(entity) or ""
  local name = EntityGetName(entity) or ""
  if name == "unknown" then name = "" end
  local path = EntityGetFilename(entity) or ""

  if match_any(tags, omit_tags) then return true end
  if match_any(name, omit_names) then return true end
  if match_any(path, omit_paths) then return true end
  return false
end

function entity_get_name(entity)
  local name = EntityGetName(entity) or ""
  if name == "" or name == "unknown" then name = "<unnamed>" end
  local path = EntityGetFilename(entity)
  if path == "" then path = "<direct>" end
  local tags = EntityGetTags(entity) or ""
  if tags == "" then tags = "<no tags>" end
  return ("%s %s %s"):format(name, tags, path)
end

function get_entity_counts(omit_rules)
  local ents = EntityGetInRadius(0, 0, math.huge)
  local counts = {}
  for _, entity in ipairs(ents) do
    if not should_omit_entity(entity, omit_rules) then
      local name = entity_get_name(entity)
      if counts[name] == nil then counts[name] = 0 end
      counts[name] = counts[name] + 1
    end
  end
  local results = {}
  for name, count in pairs(counts) do
    table.insert(results, {count, name})
  end
  table.sort(results, function(left, right)
    local lcount, rcount = left[1], right[1]
    local lname, rname = left[2], right[2]
    if lcount == rcount then return lname < rname end
    return lcount < rcount
  end)
  return results
end

omit_tags = {
  "",
  "card_action",
  "wand",
  "player_unit",
  "perk_entity",
  "coop_respawn",
  "music",
  "world_state", "controls_", "player_arm_r", "vegetation"
}
omit_names = {}
omit_paths = {"mods/", "workshop", "player.xml"}
for _, entry in ipairs(get_entity_counts{tags=omit_tags, names=omit_names, paths=omit_paths}) do
  print(entry[1], entry[2])
end
