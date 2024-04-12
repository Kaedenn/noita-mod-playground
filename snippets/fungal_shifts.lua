if self and self.host then self.host:text_clear() end
function get_shift_map()
  local world = EntityGetWithTag("world_state")[1]
  local state = EntityGetComponent(world, "WorldStateComponent")[1]
  local shifts = ComponentGetValue2(state, "changed_materials")
  local shift_pairs = {}
  for idx = 1, #shifts, 2 do
    local mat1 = shifts[idx]
    local mat2 = shifts[idx+1]
    table.insert(shift_pairs, {mat1, mat2})
  end
  return shift_pairs
end
local shifts = get_shift_map()
print(("There have been %d fungal shift(s):"):format(#shifts))
for idx, matpair in ipairs(shifts) do
  print(("%d: %s -> %s"):format(idx, matpair[1], matpair[2]))
end
