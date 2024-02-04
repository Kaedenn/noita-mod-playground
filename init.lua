-- Kae test mod

dofile("data/scripts/lib/mod_settings.lua")

dofile("mods/kae_test/files/logging.lua")
dofile("mods/kae_test/files/imguiutil.lua")
dofile("mods/kae_test/files/functions.lua")
dofile("mods/kae_test/config.lua")

KPanelLib = dofile_once("mods/kae_test/files/panel.lua")
KPanel = nil

-- Functions that may or may not be available post-init
Functions = {}

local imgui = load_imgui({version="1.14.2", mod="kae_test"})

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
    if px ~= nil and py ~= nil then
        local pw, mx = check_parallel_pos(px)
        return px, py, pw, mx
    end
    return nil, nil, nil, nil
end

function get_pos_string(player)
    local px, py, pw, mx = get_player_pos(player)
    if px == nil or py == nil then
        return "x=unknown; y=unknown"
    end
    local bx = math.floor(mx / BiomeMapGetSize())
    local by = math.floor(py / BiomeMapGetSize())
    local result = ("x=%.2f y=%.2f (map x=%d y=%d)"):format(px, py, bx, by)
    if pw ~= 0 then
        result = result .. (" world=%s"):format(pw)
        result = result .. (" local x=%.2f"):format(mx)
    end
    return result
end

function get_aplc_recipes()
    
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
        local px, py, pw, mx = get_player_pos(player_entity)
        local new_pw = nil

        if imgui.Button("Clear") then
            gui_messages = {}
        end

        if px ~= nil then
            imgui.SameLine()
            if imgui.Button("Go West") then
                new_pw = pw - 1
            end

            imgui.SameLine()
            if imgui.Button("Go East") then
                new_pw = pw + 1
            end

            if pw ~= nil and pw ~= 0 then
                imgui.SameLine()
                if imgui.Button("Go Main") then
                    new_pw = 0
                end
            end
        end

        imgui.SameLine()
        if imgui.Button("Get Position") then
            prepend_msg(get_pos_string(player_entity))
        end

        if imgui.Button("Alchemy") then
            dofile("mods/kae_test/files/aplc.lua")
            local lcc, apc, lcp, app = aplc_get()
            local lc_str = table.concat(lcc, ", ")
            local ap_str = table.concat(apc, ", ")
            add_msg(("LC: %s (%s)"):format(lc_str, lcp))
            add_msg(("AP: %s (%s)"):format(ap_str, app))
        end

        if new_pw ~= nil then
            new_px = mx + new_pw * get_world_width()
            prepend_msg(("Teleporting to %s (%s, %s)"):format(new_pw, px, py))
            EntitySetTransform(player_entity, new_px, py)
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
        KPanel:set("info")
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
