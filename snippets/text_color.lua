
ColorText = {}
function ColorText:new(imgui)
  local this = {imgui = imgui}
  setmetatable(this, { __index = self })
  return this
end

function ColorText:draw(text, color)
  self.imgui.PushStyleColor(self.imgui.Col.Text, unpack(color))
  self.imgui.Text(text)
  self.imgui.PopStyleColor()
end



