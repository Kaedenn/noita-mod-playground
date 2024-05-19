dofile_once("data/scripts/lib/utilities.lua")
-- luacheck: globals get_magnitude vec_normalize

local sprites = {
	-- sprite base 1: normal entities
	"data/particles/radar_item_faint.png",
	"data/particles/radar_item_medium.png",
	"data/particles/radar_item_strong.png",
	-- sprite base 4: heart pickups
	"mods/kae_test/files/particles/radar_heart_faint.png",
	"mods/kae_test/files/particles/radar_heart_medium.png",
	"mods/kae_test/files/particles/radar_heart_strong.png",
	-- sprite base 7: flasks/pouches
	"mods/kae_test/files/particles/radar_container_faint.png",
	"mods/kae_test/files/particles/radar_container_medium.png",
	"mods/kae_test/files/particles/radar_container_strong.png",
}

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform( entity_id )
pos_y = pos_y - 4 -- offset to middle of character

local range = 400
local indicator_distance = 22

function radar_get_items(px, py, r, tags)
	local nearby = {}
	for _, tag in ipairs(tags) do
		for _, entid in pairs(EntityGetInRadiusWithTag(px, py, r, tag)) do
			if not nearby[entid] then
				local fname = EntityGetFilename(entid)
				if fname:match("heart.xml") then
					nearby[entid] = "heart"
				else
					nearby[entid] = "item"
				end
			end
		end
	end
	return nearby
end

-- ping nearby wand
for id, kind in pairs(radar_get_items(pos_x, pos_y, range, {"item_pickup"})) do
	local wand_x, wand_y = EntityGetTransform(id)
	local parent = EntityGetRootEntity( id );

	if( IsPlayer( parent ) == false ) then 

		local dir_x = wand_x - pos_x
		local dir_y = wand_y - pos_y
		local distance = get_magnitude(dir_x, dir_y)

		-- sprite positions around character
		dir_x,dir_y = vec_normalize(dir_x,dir_y)
		local indicator_x = pos_x + dir_x * indicator_distance
		local indicator_y = pos_y + dir_y * indicator_distance

		local sprite_base = 1
		if kind == "heart" then
			sprite_base = 4
		end

		-- display sprite based on proximity
		if distance > range * 0.5 then
			GameCreateSpriteForXFrames( sprites[sprite_base], indicator_x, indicator_y )
		elseif distance > range * 0.25 then
			GameCreateSpriteForXFrames( sprites[sprite_base+1], indicator_x, indicator_y )
		elseif distance > 10 then
			GameCreateSpriteForXFrames( sprites[sprite_base+2], indicator_x, indicator_y )
		end
	end
end

-- vim: set ts=4 sts=4 sw=4 noet filetype=lua:
