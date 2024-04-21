
--[[ To run this code:
local fp = io.open("Z:\\home\\kaedenn\\Programming\\Noita\\mods\\kae_test\\snippets\\frame_func.lua", "r")
local text = fp:read("*a")
fp:close()
self:eval(text)
]]

--[[ Character table
(function(this)
if not this.env.gui then this.env.gui = GuiCreate() end
this.env.funcs["gui"] = function()
  local gui = this.env.gui
  GuiStartFrame(gui)
  for cnr = 0x20, 0xff do
    GuiText(gui, 10+((cnr-0x20)*10)%600, 60+math.floor((cnr-0x20)/60)*20, string.char(cnr))
  end
end
end)(self)
]]

(function(this)
  this.env.open = true
  this.env.id = 0
  if not this.env.gui then this.env.gui = GuiCreate() end

  this.env.funcs["gui"] = function()
    this.env.id = 0
    function next_id()
      this.env.id = this.env.id + 1
      return this.env.id
    end
    local gui = this.env.gui
    GuiStartFrame(gui)
    GuiIdPushString("kae_test_gui")
    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    local em_width, em_height = GuiGetTextDimensions(gui, "M")
    function ypos(line_nr)
      return screen_height - line_nr*em_height - 2
    end
    local line_x = 10
    local main_toggle = "[Open]"
    if this.env.open then main_toggle = "[Close]" end
    if GuiButton(gui, line_x, ypos(1), main_toggle, next_id()) then
      this.env.open = not this.env.open
    end

    function world2screen(x, y)
      local virt_x = MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")
      local virt_y = MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y")
      local cx, cy = GameGetCameraBounds()
      local screen_width, screen_height = GuiGetScreenDimensions(gui)

      local xn = (x - cx - 2.8) / (virt_x - 0) * screen_width
      local yn = (y - cy - 0.5) / (virt_y * 0.99) * screen_height
      return xn, yn
    end

    function screen2world(x, y)
      local virt_x = MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")
      local virt_y = MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y")
      local cx, cy = GameGetCameraBounds()
      local screen_width, screen_height = GuiGetScreenDimensions(gui)

      local xn = x / screen_width * (virt_x - 0) + cx + 2.8
      local yn = y / screen_height * (virt_y * 0.99) + cy + 0.5
      return xn, yn
    end

    if this.env.open then
      local player = get_players()[1]
      local px, py = EntityGetTransform(player)
      GuiText(gui, line_x, ypos(2), ("%d, %d"):format(px, py))

      -- Convert imgui mouse pos to Noita Gui mouse pos
      local mwx, mwy = DEBUG_GetMouseWorld()
      local msx, msy = world2screen(mwx, mwy)
      GuiText(gui, line_x, ypos(3),
        ("mw=%d,%d ms=%d,%d"):format(mwx, mwy, msx, msy))
      GuiText(gui, msx, msy, "*")
      --[[
      local mx, my = imgui.GetMousePos()
      local vx, vy = imgui.GetMainViewportSize()
      local mgx, mgy = InputGetMousePosOnScreen()

      local screen_x = mx / vx * screen_width
      local screen_y = my / vy * screen_height

      GuiText(gui, line_x, ypos(4),
        ("imgui mouse=[%0.2f, %0.2f] screen=[%0.2f, %0.2f]"):format(
          mx, my, vx, vy))
      GuiText(gui, line_x, ypos(3),
        ("noita mouse=[%d, %d] screen=[%d, %d]"):format(
          mgx, mgy, screen_width, screen_height))

      local cx, cy, cw, ch = GameGetCameraBounds()
      GuiText(gui, line_x, ypos(5), ("camera = %d, %d, %d, %d"):format(
        cx, cy, cw, ch))

      local centerx = cx + cw/2
      local centery = cy + ch/2

      if DEBUG_GetMouseWorld then
        local mwx, mwy = DEBUG_GetMouseWorld()
        GuiText(gui, line_x, ypos(6), ("mwx=%d, mwy=%d"):format(mwx, mwy))
      else
        GuiText(gui, line_x, ypos(6), "DEBUG_GetMouseWorld not available")
      end

      GuiText(gui, screen_x, screen_y, ("%d %d"):format(screen_x, screen_y))
      --]]
    end

    GuiIdPop(gui)
  end
end)(self)

--[[if not self.env.gui then self.env.gui = GuiCreate() end
self.env.funcs["gui"] = function()
  local gui = self.env.gui
  GuiStartFrame(gui)
  local pad_x, pad_y = 10, 2
  local screen_width, screen_height = GuiGetScreenDimensions(gui)
  local em_width, em_height = GuiGetTextDimensions(gui, "M")
  GuiText(gui, pad_x, screen_height-em_height-pad_y, "[X]")
end]]
