
dofile("mods/kae_test/files/lib/json.lua")
dofile("mods/kae_test/files/lib/smallfolk.lua")

data = ModSettingGet("spell_lab_saved_wands")
wands = smallfolk.loads(data)
print(("Saved %d wands"):format(#wands))
json_data = JSON:encode(wands)
imgui.SetClipboardText(json_data)
print(("Copied %d characters to the clipboard"):format(#json_data))

