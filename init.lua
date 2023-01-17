-- Kae test mod

dofile("data/scripts/lib/mod_settings.lua")

dofile("mods/kae_test/files/logging.lua")
dofile("mods/kae_test/files/imguiutil.lua")

KPanel = dofile_once("mods/kae_test/files/gui.lua")
KPanel2Lib = dofile_once("mods/kae_test/files/panel.lua")
KPanel2 = nil

local imgui = load_imgui({version="1.0.0", mod="kae_test"})

local gui_messages = {}

TEXT_SIZE = 256

CONF_ENABLE = "kae_test.enable"

function add_msg(msg)
    table.insert(gui_messages, msg)
end

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
    debug_msg(("px=%s py=%s pw=%s mx=%s"):format(px, py, pw, mx))
    local pos_string = ("x=%.2f y=%.2f"):format(px, py)
    pos_string = pos_string .. (" pw=%s"):format(pw)
    if mx and mx ~= px then
        pos_string = pos_string .. (" local x=%.2f"):format(mx)
    end
    return pos_string
end

-- Execute code with an optional additional environment object. Returns:
--      parse result, parse error, eval result, eval error
--
-- On parse failure, both eval result and eval error will be nil.
--
-- On eval error, obtain the error message and traceback via env.exception:
--      env.exception[1]    error message
--      env.exception[2]    traceback string
function eval_code(code, penv)
    local env = penv or {}
    if env.imgui == nil then env.imgui = imgui end

    local function code_on_error(errmsg)
        GamePrint(errmsg)
        add_msg(errmsg)
        if env then env.exception = {errmsg, debug.traceback()} end
    end

    debug_msg(("eval %s"):format(code))
    local cresult, cerror = load(code)
    debug_msg(("cr = %s, ce = %s"):format(cresult, cerror))
    if type(cresult) == "function" then
        local code_func = cresult
        --local code_func = setfenv(cresult, setmetatable(env, { __index = _G }))
        local presult, pvalue = xpcall(code_func, code_on_error)
        return cresult, cerror, presult, pvalue
    end
    return cresult, cerror, nil, nil
end

DrawFuncs = {}
function add_draw_func(func)
    DrawFuncs[tostring(func)] = func
end

function remove_draw_func(func)
    if DrawFuncs[tostring(func)] ~= nil then
        -- So, how do we delete a named entry?
        DrawFuncs[tostring(func)] = nil
        return true
    end
    return false
end

function _build_menu_bar_gui()
    if imgui.BeginMenuBar() then
        local function do_build_menu()
            if KPanel2 and KPanel2.build_menu then
                KPanel2:build_menu(imgui)
            end
        end
        local pres, pval = pcall(do_build_menu)
        if not pres then add_msg(("do_build('%s')"):format(pval)) end

        if imgui.BeginMenu("Actions") then
            --local mstr = "Enable"
            --if kae_logging() then mstr = "Disable" end
            --if imgui.MenuItem(mstr .. " Debugging") then
            --    kae_set_logging(not kae_logging())
            --end
            if imgui.MenuItem("Clear") then
                gui_messages = {}
            end
            if imgui.MenuItem("Close") then
                ModSettingSetNextValue(CONF_ENABLE, false, false)
            end
            imgui.EndMenu()
        end

        --KPanel.build_panel_menu(imgui, _G)

        if imgui.BeginMenu("Support") then
            --[[if imgui.MenuItem("Dump ImGui") then
                add_msg("Dumping imgui...")
                for _, line in ipairs(dump_library(imgui, {})) do
                    add_msg(line)
                end
            end]]
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

local eval_input_text = ""
function _build_gui()
    local player_entity = get_players()[1]

    if KPanel2:current() ~= nil then
        local function runner()
            return KPanel2:draw(imgui)
        end
        local panel_result, panel_value = pcall(runner)
        if not panel_result then
            imgui.Text(tostring(panel_value))
        end
    elseif KPanel.get_current_panel() ~= nil then
        local panel_result, panel_value = pcall(KPanel.draw_panel, imgui, _G)
        if not panel_result then
            imgui.Text(tostring(panel_value))
        end
    else
        imgui.Text("Eval")
        imgui.SameLine()

        local ret
        ret, eval_input_text = imgui.InputText("", eval_input_text, TEXT_SIZE)
        --[[
        if ret then
            add_msg(("eval('%s')"):format(str))
            local result, errmsg = load(str)
            add_msg(('result = %s, errmsg = %s'):format(result, errmsg))
            if not errmsg and type(result) == "function" then
                value = result()
                add_msg(("value = %s"):format(value))
            end
            ret = false
            str = ""
        end
        --]]
        if imgui.Button("Run") then
            local code_env = {}
            debug_msg(("ret = %s, str = '%s'"):format(ret, eval_input_text))
            local cresult, cerror, presult, pvalue = eval_code(eval_input_text, code_env)
            debug_msg(("cr = %s, ce = %s, pr = %s, pv = %s"):format(
                cresult, cerror, presult, pvalue))
            if code_env.exception ~= nil then
                add_msg(("received exception: %s"):format(code_env.exception[1]))
            end
            if cerror ~= nil then
                -- code parse failure
                add_msg(("load() error: %s"):format(cerror))
            elseif presult ~= true then
                -- code execute failure
                add_msg(("eval() error: %s"):format(pvalue))
            else
                -- success
                add_msg(("%s"):format(pvalue))
            end
            --[[local cresult, cerror = load(eval_input_text)
            if type(cresult) == "function" then
                debug_msg(("compile result: %s (error: %s)"):format(cresult, cerror))
                local presult, pvalue = xpcall(cresult, on_error)
                debug_msg(("code success: %s"):format(presult))
                debug_msg(("value: %s"):format(pvalue))
                if presult then
                    add_msg(("%s"):format(pvalue))
                end
            else
                if cresult ~= nil then
                    add_msg(("error: expected function, got %s, %s"):format(
                        type(cresult), cresult))
                end
                add_msg(("error: %s"):format(cerror))
            end
            --]]
        end

        imgui.SameLine()

        if imgui.Button("Clear") then
            gui_messages = {}
        end

        if imgui.Button("Get Position") then
            add_msg(get_pos_string(player_entity))
        end

        if imgui.Button("Go West") then
            local px, py, pw, mx = get_player_pos(player_entity)
            px = px - get_world_width()
            add_msg(("Teleporting to %s, %s"):format(px, py))
            EntitySetTransform(player_entity, px, py)
        end
        imgui.SameLine()
        if imgui.Button("Go East") then
            local px, py, pw, mx = get_player_pos(player_entity)
            px = px + get_world_width()
            add_msg(("Teleporting to %s, %s"):format(px, py))
            EntitySetTransform(player_entity, px, py)
        end

        imgui.Text("Output")

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

function OnWorldInitialized() end

function OnModPostInit() end

function OnPlayerSpawned(player_entity)
    if not KPanel2 then
        KPanel2 = KPanel2Lib:new()
    end
    if not KPanel2 then
        add_msg("Failed KPanel2:new()")
    elseif not KPanel2.initialized then
        KPanel2:init(_G)
    end
end

function OnWorldPostUpdate()
    local window_flags = imgui.WindowFlags.NoFocusOnAppearing + imgui.WindowFlags.MenuBar + imgui.WindowFlags.NoNavInputs
    if ModSettingGet(CONF_ENABLE) then
        if imgui.Begin("Kae", nil, window_flags) then
            _build_menu_bar_gui()
            _build_gui()
            imgui.End()
        end
    end
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
