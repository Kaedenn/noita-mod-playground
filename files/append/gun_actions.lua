-- luacheck: globals actions ACTION_TYPE_OTHER
table.insert(actions, 
{
	id          = "KAE_TEST_SPELL",
	name 		= "Kae's Test",
	description = "Casting this spell does nothing",
	sprite 		= "data/ui_gfx/gun_actions/chainsaw.png",
	sprite_unidentified = "data/ui_gfx/gun_actions/chainsaw_unidentified.png",
	type 		= ACTION_TYPE_OTHER,
	spawn_level                       = "",
	spawn_probability                 = "",
	price = 10,
	mana = 0,
	--max_uses = 1,
	action = function()
		-- luacheck: globals c reflecting
		for field, value in pairs(c) do
			local value_str = tostring(value)
			if type(value) == "number" then
			elseif type(value) == "string" then
				value_str = ("%q"):format(value)
			elseif type(value) == "boolean" then
				value_str = value and "true" or "false"
			elseif type(value) == "table" then
				value_str = "table"
			end
			print(("c.%s = [%s] %s"):format(field, type(value), value_str))
		end
		c.fire_rate_wait = c.fire_rate_wait + 600
		current_reload_time = current_reload_time + 600
	end,
})

-- vim: set ts=4 sts=4 sw=4 noet nolist:
