-- =======================================================
-- FPS BOOST Advanced v3.3.0 (War Within, Settings API, Export/Import support)
-- Author: jvdTitaN (improved)
-- =======================================================

local ADDON = "FPS BOOST Advanced"
local VERSION = "3.3.0"

_G.FPSBOOST = _G.FPSBOOST or {}
FPSBOOST.ADDON = ADDON
FPSBOOST.VERSION = VERSION

-- ================= Saved Vars =================
JVDTITAN_FPS_DB = JVDTITAN_FPS_DB or {
  shown = true,
  overlay = { enabled = true, fontSize = 14, y = -2, outline = false, color = {1,1,1}, scale = 1.0 },
  profile = 1,
  pos = {point="CENTER", x=0, y=0},
  safe = false,
  buttonSize = 44,
  buttonIcon = "Interface\\Icons\\Ability_Rogue_Sprint"
}

-- Key CVars we control
local KEY_CVARS = {
  "spellClutter","SpellClutterRangeConstant","particleDensity",
  "groundEffectDensity","groundEffectDist","shadowMode",
  "ffxGlow","ffxDeath","gxMaxFrameLatency","maxFPS","maxFPSBk",
  "ffxAntiAliasingMode","raidGraphicsEnvironmentDetail","raidGraphicsGroundClutter",
  "hwDetect","raidGraphicsSpellDensity","floatingCombatTextCombatHealing"
}

-- Helpers
local function say(msg)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff["..ADDON.."]|r "..msg)
  else
    print("["..ADDON.."] "..msg)
  end
end
local function warn(msg) say("|cffff7f00WARNING:|r "..msg) end
local function safeSet(name, value) pcall(SetCVar, name, value) end
local function play(id) if PlaySound and id then PlaySound(id, "Master") end end

FPSBOOST.say = say
FPSBOOST.warn = warn
FPSBOOST.safeSet = safeSet

-- ================= Core UI (Main Button) =================
local btn = CreateFrame("Button", "FPSBOOST_ADV_BTN", UIParent, "BackdropTemplate")
btn:SetSize(JVDTITAN_FPS_DB.buttonSize or 44, JVDTITAN_FPS_DB.buttonSize or 44)
btn:SetFrameStrata("HIGH")
btn:SetMovable(true); btn:EnableMouse(true)
btn:RegisterForDrag("LeftButton")
btn:SetScript("OnDragStart", function(self) self:StartMoving() end)
btn:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p,_,_,x,y = self:GetPoint()
    JVDTITAN_FPS_DB.pos = {point=p, x=x, y=y}
end)

local function restoreMainPos()
  btn:ClearAllPoints()
  local pos = JVDTITAN_FPS_DB.pos or {point="CENTER",x=0,y=0}
  btn:SetPoint(pos.point, pos.x, pos.y)
end

restoreMainPos()

local tex = btn:CreateTexture(nil, "ARTWORK")
tex:SetAllPoints(true)
tex:SetTexture(JVDTITAN_FPS_DB.buttonIcon or "Interface\\Icons\\Ability_Rogue_Sprint")

local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
label:SetPoint("BOTTOM", btn, "TOP", 0, 2)
label:SetText("Ultra")

-- FPS Overlay
local fpsText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
fpsText:SetPoint("TOP", btn, "BOTTOM", 0, JVDTITAN_FPS_DB.overlay.y or -2)
fpsText:SetText("FPS: 0")
local defaultFontPath, defaultFontSize, defaultFontFlags = fpsText:GetFont()

local function ApplyOverlayStyle()
  local o = JVDTITAN_FPS_DB.overlay or {}
  if not o.enabled then fpsText:Hide() else fpsText:Show() end
  local size = o.fontSize or 14
  local outline = o.outline and "OUTLINE" or ""
  local color = o.color or {1,1,1}
  fpsText:SetFont(defaultFontPath, size, outline)
  fpsText:SetTextColor(color[1] or 1, color[2] or 1, color[3] or 1)
  fpsText:ClearAllPoints()
  fpsText:SetPoint("TOP", btn, "BOTTOM", 0, o.y or -2)
  fpsText:SetScale(o.scale or 1.0)
end

local function UpdateFPS()
  if not (JVDTITAN_FPS_DB.overlay and JVDTITAN_FPS_DB.overlay.enabled) then fpsText:Hide(); return end
  ApplyOverlayStyle()
  fpsText:SetText("FPS: "..string.format("%.0f", GetFramerate()))
end

local fpsFrame = CreateFrame("Frame")
fpsFrame:SetScript("OnUpdate", function(self, elapsed)
  self.t = (self.t or 0) + elapsed
  if self.t > 1 then self.t = 0; UpdateFPS() end
end)

-- Animate
local glow = btn:CreateTexture(nil, "OVERLAY")
glow:SetTexture("Interface\\Cooldown\\star4")
glow:SetBlendMode("ADD")
glow:SetAllPoints(btn)
glow:Hide()
local animRunning = false
local function AnimateButton()
  if animRunning then return end
  animRunning = true
  glow:Show(); glow:SetAlpha(1)
  C_Timer.After(0.15, function() glow:Hide(); animRunning = false end)
end

-- Profiles
local profiles_builtin = {
  [1] = { name="Ultra Boost", color={0,1,0,1}, sound=SOUNDKIT.IG_ABILITY_PAGE_TURN, cvars=function()
      safeSet("spellClutter", 0); safeSet("SpellClutterRangeConstant", 0); safeSet("particleDensity", 0.3)
      safeSet("groundEffectDensity", 16); safeSet("groundEffectDist", 1); safeSet("shadowMode", 0)
      safeSet("ffxGlow", 0); safeSet("ffxDeath", 0)
      safeSet("gxMaxFrameLatency", 0); safeSet("maxFPS", 0); safeSet("maxFPSBk", 30)
      safeSet("ffxAntiAliasingMode", 0)
      safeSet("raidGraphicsEnvironmentDetail", 1); safeSet("raidGraphicsGroundClutter", 1)
      safeSet("raidGraphicsSpellDensity", 1)
      safeSet("floatingCombatTextCombatHealing", 0)
      safeSet("hwDetect", 0)
  end, chatColor="|cff00ff00"},
  [2] = { name="Balanced", color={1,1,0,1}, sound=SOUNDKIT.IG_MAINMENU_OPEN, cvars=function()
      safeSet("spellClutter", 1); safeSet("SpellClutterRangeConstant", 5); safeSet("particleDensity", 50)
      safeSet("groundEffectDensity", 64); safeSet("groundEffectDist", 32); safeSet("shadowMode", 1)
      safeSet("ffxGlow", 0); safeSet("ffxDeath", 0)
      safeSet("gxMaxFrameLatency", 1); safeSet("maxFPS", 0); safeSet("maxFPSBk", 30)
      safeSet("ffxAntiAliasingMode", 1)
      safeSet("raidGraphicsEnvironmentDetail", 5); safeSet("raidGraphicsGroundClutter", 5)
      safeSet("raidGraphicsSpellDensity", 3)
      safeSet("floatingCombatTextCombatHealing", 1)
      safeSet("hwDetect", 0)
  end, chatColor="|cffffff00"},
  [3] = { name="Quality", color={1,0,0,1}, sound=SOUNDKIT.IG_ABILITY_PAGE_TURN, cvars=function()
      safeSet("spellClutter", 1); safeSet("SpellClutterRangeConstant", 10); safeSet("particleDensity", 100)
      safeSet("groundEffectDensity", 128); safeSet("groundEffectDist", 64); safeSet("shadowMode", 3)
      safeSet("ffxGlow", 1); safeSet("ffxDeath", 1)
      safeSet("gxMaxFrameLatency", 1); safeSet("maxFPS", 0); safeSet("maxFPSBk", 60)
      safeSet("ffxAntiAliasingMode", 2)
      safeSet("raidGraphicsEnvironmentDetail", 10); safeSet("raidGraphicsGroundClutter", 10)
      safeSet("raidGraphicsSpellDensity", 5)
      safeSet("floatingCombatTextCombatHealing", 1)
      safeSet("hwDetect", 0)
  end, chatColor="|cff00ccff"},
}

local function ApplyProfileByData(pdata)
  if not pdata then return end
  if JVDTITAN_FPS_DB.safe then warn("Safe Mode is ON. Profiles won't change CVars."); return end
  if type(pdata.cvars)=="function" then pdata.cvars() end
  if pdata.color then tex:SetVertexColor(pdata.color[1], pdata.color[2], pdata.color[3], pdata.color[4]) end
  if pdata.name then label:SetText(pdata.name) end
  if pdata.sound then play(pdata.sound) end
  AnimateButton()
  if pdata.chatColor then
    say("Activated: "..pdata.chatColor..(pdata.name or "Profile").."|r")
  else
    say("Activated: "..(pdata.name or "Profile"))
  end
end

local function GetActiveProfileData()
  local id = JVDTITAN_FPS_DB.profile or 1
  return profiles_builtin[id]
end

local function ApplyActive() ApplyProfileByData(GetActiveProfileData()) end

local function SetActiveProfile(id)
  local pdata = profiles_builtin[id]
  if not pdata then warn("Invalid profile id: "..tostring(id)) return end
  JVDTITAN_FPS_DB.profile = id
  ApplyProfileByData(pdata)
end

btn:SetScript("OnClick", function(self, button)
  local nextId = (JVDTITAN_FPS_DB.profile % 3) + 1
  SetActiveProfile(nextId)
end)
btn:RegisterForClicks("LeftButtonUp")

-- ================= Reset =================
local function ResetToDefaults()
  if InCombatLockdown and InCombatLockdown() then
    warn("Cannot reset CVars while in combat.")
    return
  end
  say("Resetting CVars to Blizzard defaults...")
  for _,k in ipairs(KEY_CVARS) do
    local defaultVal = (GetCVarDefault and GetCVarDefault(k)) or nil
    if defaultVal ~= nil then SetCVar(k, defaultVal) end
  end
  say("|cffff0000All CVars reset to defaults.|r")
end

-- ======= Expose helpers for options.lua =======
function FPSBOOST.ApplyButtonSize(sz) if btn then btn:SetSize(sz, sz) end end
function FPSBOOST.ApplyButtonIcon(path) if tex and path then tex:SetTexture(path) end end
FPSBOOST.UpdateFPS = UpdateFPS
FPSBOOST.ApplyOverlayStyle = ApplyOverlayStyle
FPSBOOST.ApplyActive = ApplyActive
FPSBOOST.SetActiveProfile = SetActiveProfile
FPSBOOST.ResetToDefaults = ResetToDefaults
FPSBOOST.GetActiveProfileData = GetActiveProfileData
FPSBOOST.KEY_CVARS = KEY_CVARS

-- ================= Slash Commands =================
SLASH_FPSBOOST1 = "/fpsboost"
SlashCmdList["FPSBOOST"] = function(msg)
  msg = (msg or ""):lower()
  if msg == "help" or msg=="" then
    say("Commands:")
    say("/fpsboost help - show this help")
    say("/fpsboost info - addon info")
    say("/fpsprofile <id> - switch profile")
    say("/fpsoverlay <on|off> - toggle FPS overlay")
    say("/fpsreset - reset CVars to default")
    say("/fpsrestart - restart graphics engine")
    say("/fpscheck - show current CVars")
    say("/fpssafe <on|off> - toggle Safe Mode")
    return
  elseif msg=="info" then
    say(ADDON.." v"..VERSION.." by |cff00ffffjvdTitaN|r - War Within build")
  end
end

SLASH_FPSPROFILE1 = "/fpsprofile"
SlashCmdList["FPSPROFILE"] = function(msg)
  local id = tonumber((msg or ""))
  if id then SetActiveProfile(id) else warn("Usage: /fpsprofile <id>") end
end

SLASH_FPSOVERLAY1 = "/fpsoverlay"
SlashCmdList["FPSOVERLAY"] = function(msg)
  msg = (msg or ""):lower()
  if msg=="on" then JVDTITAN_FPS_DB.overlay.enabled=true elseif msg=="off" then JVDTITAN_FPS_DB.overlay.enabled=false end
  UpdateFPS()
end

SLASH_FPSRESET1 = "/fpsreset"
SlashCmdList["FPSRESET"] = function() ResetToDefaults() end

SLASH_FPSRESTART1 = "/fpsrestart"
SlashCmdList["FPSRESTART"] = function() ConsoleExec("gxrestart") end

SLASH_FPSCHECK1 = "/fpscheck"
SlashCmdList["FPSCHECK"] = function()
  say("Current CVars:")
  for _,k in ipairs(KEY_CVARS) do
    local val = GetCVar(k) or "nil"
    say(" - "..k.." = "..val)
  end
end

SLASH_FPSSAFE1 = "/fpssafe"
SlashCmdList["FPSSAFE"] = function(msg)
  msg = (msg or ""):lower()
  if msg=="on" then JVDTITAN_FPS_DB.safe=true; say("Safe Mode |cff00ff00ENABLED|r")
  elseif msg=="off" then JVDTITAN_FPS_DB.safe=false; say("Safe Mode |cffff0000DISABLED|r")
  else warn("Usage: /fpssafe <on|off>") end
end

-- ================= Init =================
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function()
  if JVDTITAN_FPS_DB.shown then btn:Show() else btn:Hide() end
  restoreMainPos()
  FPSBOOST.ApplyButtonSize(JVDTITAN_FPS_DB.buttonSize or 44)
  FPSBOOST.ApplyButtonIcon(JVDTITAN_FPS_DB.buttonIcon or "Interface\\Icons\\Ability_Rogue_Sprint")
  ApplyActive()
  say("Loaded v"..VERSION.." - Settings panel in ESC > Options > AddOns")
end)
