---@diagnostic disable: undefined-global
-- options/Color.lua - the colour control, opening Blizzard's own colour picker.
local _, ns = ...
local Kit = ns.OptionsKit
local Controls = Kit and Kit.Controls
if not Controls then return end

-- The renderer can recycle a row only after the native picker has closed.
Controls.IsColorOpen = function()
  local picker = ColorPickerFrame
  if not (picker and picker:IsShown()) then return false end
  if picker.GetExtraInfo then return picker:GetExtraInfo() == ns end
  return picker.extraInfo == ns
end
Controls.CloseColor = function()
  if not Controls.IsColorOpen() then return end
  if ColorPickerFrame.OnCancel then ColorPickerFrame:OnCancel() else HideUIPanel(ColorPickerFrame) end
end

-- Retail, Forever and current Classic clients take one info table. Older clients
-- read the same fields off the frame itself.
local function ShowPicker(info)
  local picker = ColorPickerFrame
  if picker.SetupColorPickerAndShow then
    picker:SetupColorPickerAndShow(info)
    return
  end
  picker.func, picker.opacityFunc, picker.cancelFunc = info.swatchFunc, info.opacityFunc, info.cancelFunc
  picker.hasOpacity, picker.opacity, picker.extraInfo = info.hasOpacity, 1 - (info.opacity or 1), info.extraInfo
  picker:SetColorRGB(info.r, info.g, info.b)
  ShowUIPanel(picker)
end

local function PickerAlpha()
  local picker = ColorPickerFrame
  if picker.GetColorAlpha then return picker:GetColorAlpha() end
  return 1 - (OpacitySliderFrame and OpacitySliderFrame:GetValue() or 0)
end

Controls.CreateColor = function(parent)
  local control = Controls.CreateButton(parent)
  control.kind = "color"
  local swatch = control.box:CreateTexture(nil, "ARTWORK")
  swatch:SetSize(30, 16)
  swatch:SetPoint("LEFT", control.box, "LEFT", 8, 0)
  control.swatch = swatch
  control.text:SetPoint("LEFT", control.box, "LEFT", 44, 0)
  control.SetValue = function(self, r, g, b, a)
    self.r, self.g, self.b, self.a = r or 1, g or 1, b or 1, a or 1
    swatch:SetColorTexture(self.r, self.g, self.b, self.a)
    self:SetText(string.format("#%02X%02X%02X", math.floor(self.r * 255 + .5), math.floor(self.g * 255 + .5), math.floor(self.b * 255 + .5)))
  end
  control.box:SetScript("OnClick", function()
    if control.disabled then return end
    ColorPickerFrame:Hide()
    local r, g, b, a = control.r, control.g, control.b, control.a
    -- Capture the binding, never a pooled row's future callback.
    local callback = control.callback
    local function apply(red, green, blue, alpha)
      control:SetValue(red, green, blue, alpha)
      if callback then callback(control, red, green, blue, alpha) end
    end
    local ready = false
    local function changed()
      if not ready then return end
      local red, green, blue = ColorPickerFrame:GetColorRGB()
      apply(red, green, blue, control.hasAlpha and PickerAlpha() or a)
    end
    ShowPicker({
      r = r, g = g, b = b, opacity = a, hasOpacity = control.hasAlpha,
      swatchFunc = changed, opacityFunc = changed,
      cancelFunc = function() apply(r, g, b, a) end, extraInfo = ns,
    })
    ready = true
  end)
  control:SetValue(1, 1, 1, 1)
  return control
end

local create = Controls.Create
Controls.Create = function(parent, kind, ...)
  if kind == "color" then return Controls.CreateColor(parent) end
  return create(parent, kind, ...)
end
