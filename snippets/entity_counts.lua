self.host:text_clear()

function entity_get_name(entity)
  local name = EntityGetName(entity) or ""
  if name == "" or name == "unknown" then name = "<unnamed>" end
  local path = EntityGetFilename(entity)
  if path == "" then path = "<direct>" end
  local tags = EntityGetTags(entity) or ""
  if tags == "" then tags = "<no tags>" end
  return ("%s %s %s"):format(name, tags, path)
end

function omit_entity(entity, omit)
  if type(omit) ~= "table" then return false end
  if #omit == 0 then return false end
  local tags = EntityGetTags(entity)
  for _, tag in ipairs(omit) do
    if #tag == 0 and #tags == 0 then
      return true
    elseif #tag > 0 then
      local spos, epos = tags:find(tag)
      if spos ~= nil and epos ~= nil then
        if spos >= 1 and epos <= #tags then return true end
      end
    end
  end
  return false
end

function get_entity_counts(omit_tags)
  local omit = omit_tags or {}
  local ents = EntityGetInRadius(0, 0, math.huge)
  local counts = {}
  for _, entity in ipairs(ents) do
    if not omit_entity(entity, omit) then
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
  "world_state",
}
for _, entry in ipairs(get_entity_counts(omit_tags)) do
  print(entry[1], entry[2])
end
