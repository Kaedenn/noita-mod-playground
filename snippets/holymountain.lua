function find_holy_mountains()
  local prev_biome = "?"
  local mountains = {}
  for y = 0, 15000, 500 do
    local biome = BiomeMapGetName(0, y)
    if biome == "$biome_holymountain" then
      mountains[prev_biome] = y
    else
      prev_biome = biome
    end
  end

  local function refine_biome(y0)
    for y = y0, y0+500, 10 do
      local biome = BiomeMapGetName(0, y)
      if biome ~= "$biome_holymountain" then
        return y-10
      end
    end
    return y0
  end

  local result = {}
  for biome_name, ypos in pairs(mountains) do
    table.insert(result, {biome_name, refine_biome(ypos) - 200})
  end
  return result
end
