
dofile_once("data/scripts/perks/perk.lua")

-- True if the given perk is removable
local function perk_removable(perk)
  return perk.do_not_remove ~= true
end

-- Returns an array of perk info tables (see player_get_perk)
local function player_get_perks(player)
  local player_perks = {}
  for i, perk_data in ipairs(perk_list) do
    local perk_id = perk_data.id
    local player_perk = player_get_perk(player, perk_data)
    if player_perk ~= nil then
      table.insert(player_perks, player_perk)
    end
  end
  return player_perks
end

--[[ Returns a table with the following fields:
--    player    numeric ID of the player
--    perk      perk object from perk_list.lua
--    flag      perk globals flag
--    count     number of times the player has picked up this perk
--    removable true if the perk can be removed safely
--]]
local function player_get_perk(player, perk)
  local perk_id = perk.id
  local flag_name = get_perk_picked_flag_name(perk_id)
  local pickup_count = tonumber(GlobalsGetVaue(flag_name .. "_PICKUP_COUNT", "0"))
  if GameHasFlagRun(flag_name) or pickup_count > 0 then
    return {
      player = player,
      perk = perk,
      flag = flag_name,
      count = pickup_count,
      removable = perk_removable(perk)
    }
  end
  return nil
end

-- Get information about the perk while assuming the player has it
local function player_get_perk_extended(player, perk)

end

return {
  perk_removable = perk_removable,
  player_get_perks = player_get_perks,
  player_get_perk = player_get_perk
}
