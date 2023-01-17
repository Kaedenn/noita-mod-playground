-- Invoke functions and catch any errors they might raise

-- Configuration flags for build_error_callback
CB = {
    NONE = 0,
    APPEND = 1, -- don't overwrite output fields
}

function trim_stack(frames, count)
    for i = 1, count do
        table.remove(frames, 1)
    end
    return frames
end

function parse_stack_frame(line)
    local loc, func = line:match("^[%s]*(.*): in (.*)")
    if loc and func then
        local file, line = loc:match("(.*):([%d]+)")
        if not file then file = loc end
        if not line then line = "" end
        return {file, line, func}
    end

    loc, func = line:match("^[%s]*(.*): at (.*)")
    if loc and func then
        return {file, "", func}
    end

    return {"", "", line}
end

-- Parse the output of debug.traceback(). Returns two array-like tables:
--      errors, frames = parse_stack_trace(traceback)
-- where `errors` is a table of strings and `frames` is a table of
--      { file_name, line, function_name }
-- All entries are strings.
function parse_stack_trace(traceback)
    local errors = {}
    local frames = {}
    local block = 0
    for line in traceback:gmatch("[^\n]+") do
        if block == 1 then
            local frame = parse_stack_frame(line)
            table.insert(frames, frame)
        elseif line:gmatch("stack traceback:") then
            block = 1
        else
            table.insert(errors, line)
        end
    end
    return errors, frames
end

-- Determine the current call stack. The first `adjust` entries are
-- removed. `adjust` defaults to 1 if omitted. Returns a table of stack
-- frames. See parse_stack_trace for that table's structure.
--
-- Equivalent to the following block:
--      errors, frames = parse_stack_trace(debug.traceback())
--      trim_stack(frames, adjust or 1)
--      return frames
function get_stack_trace(adjust)
    local traceback = debug.traceback()

    local errors, frames = parse_stack_trace(traceback)
    frames = trim_stack(frames, adjust or 1)
    return frames
end

-- Build an error handler that stores information into the given table
function build_error_callback(output, flags)
    if flags == nil then flags = CB.NONE end

    return function(message)
        -- Sometimes the message includes a stack trace
        local frames = get_stack_trace()
        -- Add the information to the output table
        if bit.band(flags, CB.APPEND) ~= 0 then
            table.insert(output, { message, frames })
        else
            output[1] = message
            output[2] = frames
        end
    end
end

--[[
-- Invoke a function with an error handler.
--
-- result, errors = try{func, ...args}
--
-- errors will be nil if no errors were detected.
--
-- Examples:
-- the call func("hello")
-- becomes  try(func, "hello")
--
-- the call myclass:method("hello", 1)
-- becomes  try(myclass.method, myclass, "hello", 1)
--]]
function try(args)
    local func = args[1]
    local fargs = {}
    for i = 2, #args do
        fargs[i-1] = args[i]
    end
    local errors = {}
    local on_error = build_error_callback(errors, 0)
    local success, result = xpcall(func, on_error, unpack(fargs))

    if success then
        return result, nil
    end
    return result, errors
end

-- vim: set ts=4 sts=4 sw=4 tw=79:
