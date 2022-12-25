-- Functions to assist with NoitaDearImGui stuff

DEFAULT_BUFFER_SIZE = 512

-- Create a text input with an associated button
--
-- Usage: TextWithButton{<positional-args>, <keyword-args>)
-- Positional arguments:
--      imgui           imgui instance table
--      input_text      starting input text or placeholder
--      button_text     button text
--      bufsize         edit buffer size (default: DEFAULT_BUFFER_SIZE)
-- Keyword arguments:
--      btn_same_line   boolean; if true, call SameLine() before Button()
--      pre_label       string; add Text(pre_label) if not nil
--      text_label      string; first argument to InputText()
-- Returns three values: button_pressed, input_success, input_text
--      button_pressed  boolean; true when button is pressed
--      input_success   boolean; true when the input is "submitted"
--      input_text      string; current value of the input box
function TextWithButton(options)
    local imgui = options[1]
    local input_text = options[2]
    local button_text = options[3]
    local bufsize = options[4] or DEFAULT_BUFFER_SIZE

    local btn_same_line = options.btn_same_line or false
    if options.pre_label then
        imgui.Text(options.pre_label)
        imgui.SameLine()
    end

    local text_label = options.text_label or ""

    local ret
    ret, input_text = imgui.TextInput(text_label, input_text, bufsize)

    if options.btn_same_line then
        imgui.SameLine()
    end

    btn_clicked = imgui.Button(button_text)
    return btn_clicked, ret, input_text
end

-- vim: set ts=4 sts=4 sw=4:

