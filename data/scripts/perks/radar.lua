dofile_once("data/scripts/lib/utilities.lua")
-- luacheck: globals get_magnitude vec_normalize is_in_camera_bounds

-- These entities will not be considered by the radar
local banned_entities = {
	["$animal_fungus_tiny"] = 1,
}

-- These additional entities will have custom radar sprites
local special_entities = {
	["$animal_hpcrystal"] = 1,
	["$animal_snowcrystal"] = 1,
}

local sprites = {
	-- sprite base 1: normal entities
	"data/particles/radar_enemy_faint.png",
	"data/particles/radar_enemy_medium.png",
	"data/particles/radar_enemy_strong.png",
	-- sprite base 4: special entities
	"mods/kae_test/files/particles/radar_eye_faint.png",
	"mods/kae_test/files/particles/radar_eye_medium.png",
	"mods/kae_test/files/particles/radar_eye_strong.png",
}

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform( entity_id )
pos_y = pos_y - 4 -- offset to middle of character

local range = 400
local indicator_distance = 20

local range_faint = range * 0.8
local range_medium = range * 0.5

function is_enemy(entid, name)
	if not name or not banned_entities[name] then
		if EntityHasTag(entid, "enemy") then
			return true
		end
	end
	return false
end

function is_special(entid, name)
	if name and special_entities[name] then
		if EntityHasTag(entid, "mortal") then
			return true
		end
	end
	return false
end

function radar_get_enemies(px, py, r, tags)
	local nearby = {}
	for _, tag in ipairs(tags) do
		for _, entid in pairs(EntityGetInRadiusWithTag(px, py, r, tag)) do
			if not nearby[entid] then
				local name = EntityGetName(entid)
				if is_enemy(entid, name) then
					nearby[entid] = {name, "enemy"}
				elseif is_special(entid, name) then
					nearby[entid] = {name, "special"}
				end
			end
		end
	end
	return nearby
end

-- ping nearby enemies
--for _, enemy_id in pairs(EntityGetInRadiusWithTag(pos_x, pos_y, range, "enemy")) do
for enemy_id, info in pairs(radar_get_enemies(pos_x, pos_y, range, {"enemy", "mortal"})) do
	local name, kind = info[1], info[2]
	local enemy_x, enemy_y = EntityGetFirstHitboxCenter(enemy_id)
	local dir_x = enemy_x - pos_x
	local dir_y = enemy_y - pos_y
	local distance = get_magnitude(dir_x, dir_y)

	local indicator_x = 0
	local indicator_y = 0

	local sprite_base = 1
	if kind == "special" then
		sprite_base = 4
	end

	if kind ~= "special" and is_in_camera_bounds(enemy_x, enemy_y, -4) then
		indicator_x = enemy_x
		indicator_y = enemy_y - 3
	else
		-- position radar indicators around character
		dir_x,dir_y = vec_normalize(dir_x,dir_y)
		indicator_x = pos_x + dir_x * indicator_distance
		indicator_y = pos_y + dir_y * indicator_distance
	end

	-- display sprite based on proximity
	if distance > range_faint then
		GameCreateSpriteForXFrames( sprites[sprite_base], indicator_x, indicator_y, true, 0, 0, 1, true )
	elseif distance > range_medium then
		GameCreateSpriteForXFrames( sprites[sprite_base+1], indicator_x, indicator_y, true, 0, 0, 1, true )
	else
		GameCreateSpriteForXFrames( sprites[sprite_base+2], indicator_x, indicator_y, true, 0, 0, 1, true )
	end
end

-- vim: set ts=4 sts=4 sw=4 noet filetype=lua:
