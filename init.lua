-- Kae test mod

dofile("data/scripts/lib/mod_settings.lua")

dofile("mods/kae_test/files/logging.lua")
dofile("mods/kae_test/files/imguiutil.lua")
dofile("mods/kae_test/files/functions.lua")
dofile("mods/kae_test/config.lua")

KPanelLib = dofile_once("mods/kae_test/files/panel.lua")
KPanel = nil

local imgui = load_imgui({version="1.0.0", mod="kae_test"})

local gui_messages = {}

function add_msg(msg) table.insert(gui_messages, msg) end
function prepend_msg(msg) table.insert(gui_messages, 1, msg) end

function debug_msg(msg)
    if kae_logging() then
        add_msg("DEBUG: " .. msg)
    end
end

function on_error(arg)
    add_msg(debug.traceback())
    if arg ~= nil then
        add_msg(arg)
    end
end

function get_world_width()
    return BiomeMapGetSize() * 512
end

function get_player_pos(player)
    local px, py = EntityGetTransform(player)
    local pw, mx = check_parallel_pos(px)
    return px, py, pw, mx
end

function get_pos_string(player)
    local px, py, pw, mx = get_player_pos(player)
    local bx = math.floor(mx / BiomeMapGetSize())
    local by = math.floor(py / BiomeMapGetSize())
    local result = ("x=%.2f y=%.2f (map x=%d y=%d)"):format(px, py, bx, by)
    if pw ~= 0 then
        result = result .. (" world=%s"):format(pw)
        result = result .. (" local x=%.2f"):format(mx)
    end
    return result
end

DrawFuncs = {}
function add_draw_func(func)
    local result = table_has(DrawFuncs, tostring(func))
    DrawFuncs[tostring(func)] = func
    return result
end

function remove_draw_func(func)
    local result
    DrawFuncs, result = table_without(DrawFuncs, tostring(func))
    return result
end

function _build_menu_bar_gui()
    if imgui.BeginMenuBar() then
        local function do_build_menu()
            if KPanel and KPanel.build_menu then
                KPanel:build_menu(imgui)
            end
        end
        local pres, pval = pcall(do_build_menu)
        if not pres then add_msg(("do_build('%s')"):format(pval)) end

        if imgui.BeginMenu("Actions") then
            if imgui.MenuItem("Clear") then
                gui_messages = {}
            end
            if imgui.MenuItem("Close") then
                conf_set(CONF.ENABLE, false)
            end
            imgui.EndMenu()
        end

        --KPanel.build_panel_menu(imgui, _G)

        if imgui.BeginMenu("Support") then
            if imgui.MenuItem("Dump _G") then
                local keys = {}
                for k, v in pairs(_G) do
                    table.insert(keys, k)
                end
                table.sort(keys)
                for i, k in ipairs(keys) do
                    add_msg(("_G.%s[%s] = %s"):format(k, type(_G[k]), _G[k]))
                end
            end
            imgui.EndMenu()
        end
        imgui.EndMenuBar()
    end
end

function _build_gui()
    local player_entity = get_players()[1]

    if not KPanel then
        GamePrint("_build_gui: KPanel not defined")
    end
    if KPanel and KPanel:current() ~= nil then
        local function runner()
            return KPanel:draw(imgui)
        end
        local panel_result, panel_value = pcall(runner)
        if not panel_result then
            imgui.Text(tostring(panel_value))
        end
    else
        if imgui.Button("Clear") then
            gui_messages = {}
        end

        imgui.SameLine()
        if imgui.Button("Go West") then
            local px, py, pw, mx = get_player_pos(player_entity)
            px = px - get_world_width()
            prepend_msg(("Teleporting to %s (%s, %s)"):format(pw-1, px, py))
            EntitySetTransform(player_entity, px, py)
        end

        imgui.SameLine()
        if imgui.Button("Go East") then
            local px, py, pw, mx = get_player_pos(player_entity)
            px = px + get_world_width()
            prepend_msg(("Teleporting to %s (%s, %s)"):format(pw+1, px, py))
            EntitySetTransform(player_entity, px, py)
        end

        imgui.SameLine()
        if imgui.Button("Get Position") then
            prepend_msg(get_pos_string(player_entity))
        end

        for index, entry in ipairs(gui_messages) do
            if type(entry) == "table" then
                for j, msg in ipairs(entry) do
                    imgui.Text(msg)
                end
            else
                imgui.Text(entry)
            end
        end

    end

    for fname, func in pairs(DrawFuncs) do
        if type(func) == "function" then
            func(imgui)
        end
    end

end

function OnWorldInitialized()
end

function OnModPostInit()
end

function OnPlayerSpawned(player_entity)
end

function OnWorldPostUpdate()
    local WF = imgui.WindowFlags
    if not KPanel then
        KPanel = KPanelLib:new()
    end
    if not KPanel then
        add_msg("Failed KPanel:new()")
        GamePrint("Failed KPanel:new()")
    elseif not KPanel.init then
        add_msg("Failed KPanel:new(); init not defined")
        GamePrint("Failed KPanel:new(); init not defined")
    elseif not KPanel.initialized then
        KPanel:init(_G)
    end
    if conf_get(CONF.ENABLE) then
        if imgui.Begin("Kae", nil, WF.NoFocusOnAppearing + WF.MenuBar + WF.NoNavInputs)
        then
            local res, val
            res, val = pcall(_build_menu_bar_gui)
            if not res then GamePrint(tostring(val)) end
            res, val = pcall(_build_gui)
            if not res then GamePrint(tostring(val)) end
            imgui.End()
        end
    end
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
