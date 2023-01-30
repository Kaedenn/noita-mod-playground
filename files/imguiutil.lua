--[[ Functions and values to assist with NoitaDearImGui ]]

--[[ Table of all keys supported by NoitaDearImGui ]]
ImguiKeys = {
    "None",
    "Tab",
    "LeftArrow",
    "RightArrow",
    "UpArrow",
    "DownArrow",
    "PageUp",
    "PageDown",
    "Home",
    "End",
    "Insert",
    "Delete",
    "Backspace",
    "Space",
    "Enter",
    "Escape",
    "LeftCtrl",
    "LeftShift",
    "LeftAlt",
    "LeftSuper",
    "RightCtrl",
    "RightShift",
    "RightAlt",
    "RightSuper",
    "Menu",
    "_0",
    "_1",
    "_2",
    "_3",
    "_4",
    "_5",
    "_6",
    "_7",
    "_8",
    "_9",
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z",
    "F1",
    "F2",
    "F3",
    "F4",
    "F5",
    "F6",
    "F7",
    "F8",
    "F9",
    "F10",
    "F11",
    "F12",
    "Apostrophe",
    "Comma",
    "Minus",
    "Period",
    "Slash",
    "Semicolon",
    "Equal",
    "LeftBracket",
    "Backslash",
    "RightBracket",
    "GraveAccent",
    "CapsLock",
    "ScrollLock",
    "NumLock",
    "PrintScreen",
    "Pause",
    "Keypad0",
    "Keypad1",
    "Keypad2",
    "Keypad3",
    "Keypad4",
    "Keypad5",
    "Keypad6",
    "Keypad7",
    "Keypad8",
    "Keypad9",
    "KeypadDecimal",
    "KeypadDivide",
    "KeypadMultiply",
    "KeypadSubtract",
    "KeypadAdd",
    "KeypadEnter",
    "KeypadEqual",
    "GamepadStart",
    "GamepadBack",
    "GamepadFaceUp",
    "GamepadFaceDown",
    "GamepadFaceLeft",
    "GamepadFaceRight",
    "GamepadDpadUp",
    "GamepadDpadDown",
    "GamepadDpadLeft",
    "GamepadDpadRight",
    "GamepadL1",
    "GamepadR1",
    "GamepadL2",
    "GamepadR2",
    "GamepadL3",
    "GamepadR3",
    "GamepadLStickUp",
    "GamepadLStickDown",
    "GamepadLStickLeft",
    "GamepadLStickRight",
    "GamepadRStickUp",
    "GamepadRStickDown",
    "GamepadRStickLeft",
    "GamepadRStickRight",
    "ModCtrl",
    "ModShift",
    "ModAlt",
    "ModSuper",
    "COUNT",
}

--[[  Return the number of array members and fields of the given table ]]
function _count_table(tab)
    local nmem = 0
    for k, v in pairs(tab) do
        nmem = nmem + 1
    end
    return #tab, nmem
end

--[[ Build a string that crudely describes the given value ]]
function describe_value(fvalue)
    local ftype = type(fvalue)
    local result = ("[%s]%s"):format(ftype, fvalue)
    if ftype == "table" then
        local tsize, tcount = _count_table(fvalue)
        if tsize == 0 and tcount == 0 then
            result = "table"
        elseif tsize > 0 and tcount == 0 then
            result = ("array[%d]"):format(tsize)
        elseif tsize == 0 and tcount > 0 then
            result = ("table[%d]"):format(tcount)
        else
            result = ("table[%d]{%d}"):format(tsize, tcount)
        end
    end
    return result
end

--[[  Return an array of strings that describe the library content ]]
function dump_library(lib, dump_flags)
    local attrs = {}
    local values = {}

    local flags = dump_flags or {}

    for fname, fvalue in pairs(lib) do
        local ftype = type(fvalue)
        if not attrs[ftype] then attrs[ftype] = {} end
        table.insert(attrs[ftype], fname)
        values[fname] = describe_value(fvalue)
    end

    for vtype, vnames in pairs(attrs) do
        table.sort(vnames)
    end

    local lines = {}
    for vtype, vnames in pairs(attrs) do
        for idx, vname in ipairs(vnames) do
            local line = ("imgui.%s = %s"):format(vname, values[vname])
            table.insert(lines, line)
        end
    end
    return lines
end

-- vim: set ts=4 sts=4 sw=4:

