dofile_once("data/scripts/lib/utilities.lua")

local banned_entities = {
	["$animal_fungus_tiny"] = 1
}

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform( entity_id )
pos_y = pos_y - 4 -- offset to middle of character

local range = 400
local indicator_distance = 20

function radar_get_near_enemies(px, py, r)
	local nearby = {}
	for _, entity_id in pairs(EntityGetInRadiusWithTag(px, py, r, "enemy")) do
		local name = EntityGetName(entity_id)
		if not name or not banned_entities[name] then
			table.insert(nearby, entity_id)
		end
	end
	return nearby
end

-- ping nearby enemies
--for _, enemy_id in pairs(EntityGetInRadiusWithTag(pos_x, pos_y, range, "enemy")) do
for _, enemy_id in ipairs(radar_get_near_enemies(pos_x, pos_y, range)) do
	local enemy_x, enemy_y = EntityGetFirstHitboxCenter(enemy_id)
	local dir_x = enemy_x - pos_x
	local dir_y = enemy_y - pos_y
	local distance = get_magnitude(dir_x, dir_y)

	local indicator_x = 0
	local indicator_y = 0

	if is_in_camera_bounds(enemy_x, enemy_y, -4) then
		indicator_x = enemy_x
		indicator_y = enemy_y - 3
	else
		-- position radar indicators around character
		dir_x,dir_y = vec_normalize(dir_x,dir_y)
		indicator_x = pos_x + dir_x * indicator_distance
		indicator_y = pos_y + dir_y * indicator_distance
	end

	-- display sprite based on proximity
	if distance > range * 0.8 then
		GameCreateSpriteForXFrames( "data/particles/radar_enemy_faint.png", indicator_x, indicator_y, true, 0, 0, 1, true )
	elseif distance > range * 0.5 then
		GameCreateSpriteForXFrames( "data/particles/radar_enemy_medium.png", indicator_x, indicator_y, true, 0, 0, 1, true )
	else
		GameCreateSpriteForXFrames( "data/particles/radar_enemy_strong.png", indicator_x, indicator_y, true, 0, 0, 1, true )
	end
end

-- vim: set ts=2 sts=2 sw=2 noet filetype=lua:
