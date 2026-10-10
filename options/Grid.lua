-- A grid of buttons, for a group that is nothing but buttons (the class colours).
--
-- A row per button would run the class colours a full screen down the page, one
-- label and one button for each class, so they flow side by side instead and wrap
-- to the page's width. Same contract as every other control in Controls.lua.
local _, ns = ...
local Kit = ns.OptionsKit
local Controls = Kit.Controls

local floor, max = math.floor, math.max
local unpack = unpack

local BUTTON_W, BUTTON_H, GAP = 150, 26, 6
local PAD_LEFT, PAD_RIGHT, PAD_TOP = 14, 12, 6

Controls.CreateGrid = function(parent)
  local control = { kind = "grid", buttons = {} }

  local frame = CreateFrame("Frame", nil, parent)
  frame:SetHeight(BUTTON_H + PAD_TOP * 2)
  control.frame = frame

  local function Restyle(button)
    local disabled = button.disabled
    button.backdrop:SetBackdropColor(unpack(Kit.BackdropColor))
    Kit.SetBorderColor(button.backdrop, button.hovered and not disabled and Kit.BorderHover or Kit.BorderIdle)
    local colour = disabled and Kit.TextDisabled or button.hovered and Kit.TextHighlight or Kit.TextNormal
    button.text:SetTextColor(colour[1], colour[2], colour[3])
  end

  local function Acquire(index)
    local button = control.buttons[index]
    if button then return button end
    button = CreateFrame("Button", nil, frame)
    button:SetSize(BUTTON_W, BUTTON_H)
    button.backdrop = Kit.CreateBackdrop(button, Kit.ButtonBackdrop)
    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFontObject(Kit.GetFont(12))
    text:SetPoint("LEFT", 8, 0)
    text:SetPoint("RIGHT", -8, 0)
    text:SetWordWrap(false)
    button.text = text
    button:SetScript("OnClick", function(self)
      if self.disabled or not control.onClick then return end
      PlaySound(852)
      control.onClick(self.entry)
    end)
    button:SetScript("OnEnter", function(self)
      self.hovered = true
      Restyle(self)
      if self.help then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.text:GetText(), unpack(Kit.TextHighlight))
        GameTooltip:AddLine(self.help, Kit.TextNormal[1], Kit.TextNormal[2], Kit.TextNormal[3], true)
        GameTooltip:Show()
      end
    end)
    button:SetScript("OnLeave", function(self)
      self.hovered = nil
      Restyle(self)
      GameTooltip:Hide()
    end)
    control.buttons[index] = button
    return button
  end

  -- `describe(entry)` returns the label, the help line and whether it is disabled.
  control.SetButtons = function(self, entries, onClick, describe)
    self.onClick, self.count = onClick, #entries
    for index, entry in ipairs(entries) do
      local button = Acquire(index)
      local label, help, disabled = describe(entry)
      button.entry, button.help, button.disabled = entry, help, disabled
      button.text:SetText(label)
      if disabled then button:Disable() else button:Enable() end
      Restyle(button)
      button:Show()
    end
    for index = #entries + 1, #self.buttons do self.buttons[index]:Hide() end
  end

  control.Measure = function(self, width)
    local usable = max(BUTTON_W, (width or 0) - PAD_LEFT - PAD_RIGHT)
    local columns = max(1, floor((usable + GAP) / (BUTTON_W + GAP)))
    local buttonWidth = floor((usable - GAP * (columns - 1)) / columns)
    for index = 1, self.count or 0 do
      local button = self.buttons[index]
      local column, row = (index - 1) % columns, floor((index - 1) / columns)
      button:SetWidth(buttonWidth)
      button:ClearAllPoints()
      button:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD_LEFT + column * (buttonWidth + GAP), -PAD_TOP - row * (BUTTON_H + GAP))
    end
    self.rows = max(1, floor(((self.count or 0) + columns - 1) / columns))
    frame:SetHeight(self:GetHeight())
    return self:GetHeight()
  end

  control.GetHeight = function(self)
    local rows = self.rows or 1
    return PAD_TOP * 2 + rows * BUTTON_H + (rows - 1) * GAP
  end

  control.Restyle = function(self)
    for index = 1, self.count or 0 do Restyle(self.buttons[index]) end
  end

  control.SetLabel = function() end
  control.SetHelp = function() end
  control.SetDisabled = function() end
  control.SetModified = function() end
  control.SetCallback = function() end
  control.SetOnRevert = function() end

  return control
end

local create = Controls.Create
Controls.Create = function(parent, kind, ...)
  if kind == "grid" then return Controls.CreateGrid(parent) end
  return create(parent, kind, ...)
end
