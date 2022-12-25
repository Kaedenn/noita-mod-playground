-- Functions to assist with NoitaDearImGui

-- Return the number of array members and fields of the given table
function _count_table(tab)
    local nmem = 0
    for k, v in pairs(tab) do
        nmem = nmem + 1
    end
    return #tab, nmem
end

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

-- Return an array of strings that describe the library content
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

