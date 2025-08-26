-- ========== Options with Overlay Sliders + Color Fix ==========
local ADDON = FPSBOOST and FPSBOOST.ADDON or "FPS BOOST Advanced"

local panel = CreateFrame("Frame", "FPSBOOST_OPTIONS_PANEL_OVERLAY_COLORFIX", UIParent)
panel.name = ADDON

-- Ensure DB tables exist
if not JVDTITAN_FPS_DB.overlay then JVDTITAN_FPS_DB.overlay = {} end
if not JVDTITAN_FPS_DB.overlay.color then JVDTITAN_FPS_DB.overlay.color = {1,1,1} end

-- Title
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(ADDON.." - Settings")

-- Tab system
local tabButtons, tabFrames = {}, {}
local function CreateTab(name, idx)
  local btn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  btn:SetSize(100,22)
  btn:SetText(name)
  btn:SetID(idx)

  local frame = CreateFrame("Frame", nil, panel)
  frame:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -40)
  frame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -16, 16)
  frame:Hide()

  btn:SetScript("OnClick", function()
    for _,f in ipairs(tabFrames) do f:Hide() end
    frame:Show()
  end)

  tabButtons[idx] = btn
  tabFrames[idx] = frame
  return btn, frame
end

-- Create 4 tabs
local t1,f1 = CreateTab("Profiles",1)
t1:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
local t2,f2 = CreateTab("Overlay",2)
t2:SetPoint("LEFT", t1, "RIGHT", 8, 0)
local t3,f3 = CreateTab("Safe & Reset",3)
t3:SetPoint("LEFT", t2, "RIGHT", 8, 0)
local t4,f4 = CreateTab("Information",4)
t4:SetPoint("LEFT", t3, "RIGHT", 8, 0)

-- Safe & Reset tab content (appended after f3 definition)
local safeCB = CreateFrame("CheckButton", nil, f3, "ChatConfigCheckButtonTemplate")
safeCB:SetPoint("TOPLEFT",16,-16)
safeCB.Text:SetText("Enable Safe Mode (prevent CVars changes)")
safeCB:SetChecked(JVDTITAN_FPS_DB.safe)
safeCB:SetScript("OnClick", function(self)
  JVDTITAN_FPS_DB.safe = self:GetChecked()
  if JVDTITAN_FPS_DB.safe then
    if FPSBOOST and FPSBOOST.say then FPSBOOST.say("Safe Mode |cff00ff00ENABLED|r") end
  else
    if FPSBOOST and FPSBOOST.say then FPSBOOST.say("Safe Mode |cffff0000DISABLED|r") end
  end
end)

local resetBtn = CreateFrame("Button", nil, f3, "UIPanelButtonTemplate")
resetBtn:SetSize(160,24)
resetBtn:SetText("Reset CVars to Default")
resetBtn:SetPoint("TOPLEFT", safeCB, "BOTTOMLEFT", 0, -20)
resetBtn:SetScript("OnClick", function()
  if FPSBOOST and FPSBOOST.ResetToDefaults then
    FPSBOOST.ResetToDefaults()
  end
end)

-- Profiles tab content: just buttons
local function CreateProfileButton(parent,label,profileID,y)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(160,24)
  b:SetText(label)
  b:SetPoint("TOPLEFT",16,y)
  b:SetScript("OnClick",function()
    if FPSBOOST and FPSBOOST.SetActiveProfile then
      FPSBOOST.SetActiveProfile(profileID)
    end
  end)
  return b
end

CreateProfileButton(f1,"Ultra Boost (1)",1,-16)
CreateProfileButton(f1,"Balanced (2)",2,-48)
CreateProfileButton(f1,"Quality (3)",3,-80)

-- Overlay tab content
local function AddLabel(frame,text,x,y)
  local lbl = frame:CreateFontString(nil,"ARTWORK","GameFontHighlight")
  lbl:SetPoint("TOPLEFT",x or 16,y or -16)
  lbl:SetText(text)
  return lbl
end

-- Enable checkbox
local cb = CreateFrame("CheckButton", nil, f2, "ChatConfigCheckButtonTemplate")
cb:SetPoint("TOPLEFT",16,-16)
cb.Text:SetText("Enable FPS Overlay")
cb:SetChecked(JVDTITAN_FPS_DB.overlay.enabled)
cb:SetScript("OnClick", function(self)
  JVDTITAN_FPS_DB.overlay.enabled = self:GetChecked()
  if FPSBOOST and FPSBOOST.UpdateFPS then FPSBOOST.UpdateFPS() end
end)

-- Helper to create a slider
local function CreateSlider(parent,label,minVal,maxVal,step,initVal,y,callback)
  local lbl = AddLabel(parent,label,16,y)
  local s = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", lbl, "BOTTOMLEFT", 0, -8)
  s:SetSize(200,16)
  s:SetMinMaxValues(minVal,maxVal)
  s:SetValueStep(step)
  s:SetObeyStepOnDrag(true)
  s:SetValue(initVal or minVal)
  s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
  s:SetScript("OnValueChanged",function(self,val)
    callback(val)
  end)
  return s
end

-- Font Size slider
CreateSlider(f2,"Font Size:",10,30,1,JVDTITAN_FPS_DB.overlay.fontSize or 14,-56,function(val)
  JVDTITAN_FPS_DB.overlay.fontSize=val
  if FPSBOOST and FPSBOOST.ApplyOverlayStyle then FPSBOOST.ApplyOverlayStyle() end
  if FPSBOOST and FPSBOOST.UpdateFPS then FPSBOOST.UpdateFPS() end
end)

-- Y Offset slider
CreateSlider(f2,"Y Offset:",-200,200,10,JVDTITAN_FPS_DB.overlay.y or -2,-120,function(val)
  JVDTITAN_FPS_DB.overlay.y=val
  if FPSBOOST and FPSBOOST.ApplyOverlayStyle then FPSBOOST.ApplyOverlayStyle() end
  if FPSBOOST and FPSBOOST.UpdateFPS then FPSBOOST.UpdateFPS() end
end)

-- Information tab content
local infoText = AddLabel(f4, "Type /fpsboost help in chat to see all commands.",16,-16)

-- Buttons for each slash command
local function CreateInfoButton(parent,label,command,y)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetSize(200,22)
  b:SetText(label)
  b:SetPoint("TOPLEFT",16,y)
  b:SetScript("OnClick", function()
    if ChatFrame1 then
      ChatFrame1:AddMessage("Command executed: "..command)
    end
    ChatFrame_OpenChat(command) -- fixed for Dragonflight/WarWithin
  end)
  return b
end

CreateInfoButton(f4,"Help Command","/fpsboost help",-56)
CreateInfoButton(f4,"Show Addon Info (/fpsboost info)","/fpsboost info",-88)
CreateInfoButton(f4,"Profile 1 - Ultra Boost","/fpsprofile 1",-120)
CreateInfoButton(f4,"Profile 2 - Balanced","/fpsprofile 2",-152)
CreateInfoButton(f4,"Profile 3 - Quality","/fpsprofile 3",-184)
CreateInfoButton(f4,"FPS-show ON","/fpsoverlay on",-216)
CreateInfoButton(f4,"FPS-show OFF","/fpsoverlay off",-248)
CreateInfoButton(f4,"Reset CVars","/fpsreset",-280)
CreateInfoButton(f4,"Restart Graphics","/fpsrestart",-312)
CreateInfoButton(f4,"Check CVars","/fpscheck",-344)
CreateInfoButton(f4,"Safe Mode ON","/fpssafe on",-376)
CreateInfoButton(f4,"Safe Mode OFF","/fpssafe off",-408)

-- Footer credit
local credit = f4:CreateFontString(nil,"ARTWORK","GameFontNormal")
credit:SetPoint("BOTTOMLEFT",16,16)
credit:SetText("Created by jvdTitaN - Hope you enjoy this addon!")

-- Show first tab
f1:Show()

-- Register
if Settings and Settings.RegisterCanvasLayoutCategory then
  local category=Settings.RegisterCanvasLayoutCategory(panel,ADDON)
  Settings.RegisterAddOnCategory(category)
end