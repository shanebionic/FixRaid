--- Define the minimap icon, the Fix Raid button on the raid tab, and
-- their tooltips.
local A, L = unpack(select(2, ...))
local M = A:NewModule("buttonGui", "AceEvent-3.0", "AceTimer-3.0")
A.buttonGui = M
M.private = {
  icon = false,
  iconLDB = false,
  raidTabButton = false,
  flashTimer = false,
}
local R = M.private

local NUM_FLASHES = 3
local DELAY_FLASH = 0.5

local format, strfind, strlower, time, tostring = format, strfind, strlower, time, tostring
local CreateFrame, InCombatLockdown, IsControlKeyDown, IsInGroup, IsShiftKeyDown, UnitName = CreateFrame, InCombatLockdown, IsControlKeyDown, IsInGroup, IsShiftKeyDown, UnitName
-- GLOBALS: LibStub, GameTooltip, RaidFrame, RaidFrameRaidInfoButton

local CUBE_ICON_0 = "Interface\\Addons\\"..A.NAME.."\\media\\cubeIcon0_64.tga"
local CUBE_ICON_1 = "Interface\\Addons\\"..A.NAME.."\\media\\cubeIcon1_64.tga"
local CUBE_ICON_BW = "Interface\\Addons\\"..A.NAME.."\\media\\cubeIconBW_64.tga"
local TOOLTIP_RIGHT_GUI = format(L["tooltip.right.gui"], A.util:Highlight("/fr"))

local function handleClick(_, button)
  if button == "RightButton" then
    A.frCommand:Command("")
  elseif button == "LeftButton" then
    A.frCommand:Command("default")
  elseif button == "MiddleButton" then
    A.frCommand:Command("split")
  end
end

local function watchChat(event, message, sender)
  if A.DEBUG >= 1 then A.console:Debugf(M, "watchChat event=%s message=[%s] sender=%s", event, A.util:Escape(message), sender) end
  if A.options.watchChat and sender ~= UnitName("player") and message and A.sorter:CanBegin() then
    message = strlower(message)
    -- Search for both the default and the localized keywords.
    if strfind(message, "fix%s+group") or strfind(message, "mark%s+tank") or strfind(message, "set%s+tank") or A.util:WatchChatKeywordMatches(message) then
      M:FlashRaidTabButton()
    end
  end
end

local function refresh()
  M:Refresh()
end

local function setupMinimapIcon()
  if R.icon then
    return
  end
  R.iconLDB = LibStub("LibDataBroker-1.1"):NewDataObject(A.NAME, {
    type = "launcher",
    text = A.NAME,
    icon = CUBE_ICON_1,
    OnClick = handleClick,
    OnTooltipShow = function(tooltip) M:SetupTooltip(tooltip, true) end,
  })
  R.icon = LibStub("LibDBIcon-1.0")
  R.icon:Register(A.NAME, R.iconLDB, A.options.minimapIcon)
end

local function setupRaidTabButton()
  if R.raidTabButton then
    return
  end

  -- Reference the Raid Frame and title text
  local raidFrame = RaidFrame
  local titleText = raidFrame.TitleText or raidFrame:GetChildren()

  -- Create the button
  local b = CreateFrame("Button", nil, raidFrame, "UIPanelButtonTemplate")
  b:SetSize(80, 22) -- Adjust width and height as needed
  b:SetText(L["button.fixRaid.text"])

  -- Position the button in the title bar, to the right and slightly up
  if titleText then
    b:SetPoint("TOPRIGHT", titleText, "TOPRIGHT", -20, 25)
  else
    -- Fallback to positioning in the top-right corner
    b:SetPoint("TOPRIGHT", raidFrame, "TOPRIGHT", -5, -5)
  end

  -- Optional: Adjust the button's strata and level to match the title bar
  b:SetFrameStrata("HIGH")
  b:SetFrameLevel(raidFrame:GetFrameLevel() + 1)

  -- Add background texture
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(true)
  bg:SetColorTexture(0.1, 0.1, 0.1, 0.8) -- Dark background with some transparency

  -- Add border
  local border = CreateFrame("Frame", nil, b, BackdropTemplateMixin and "BackdropTemplate")
  border:SetAllPoints(true)
  border:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
  })
  border:SetBackdropBorderColor(1, 1, 1, 1) -- White border

  -- Register scripts
  b:RegisterForClicks("AnyUp")
  b:SetScript("OnClick", handleClick)
  b:SetScript("OnEnter", function(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT")
    M:SetupTooltip(GameTooltip, false)
  end)
  b:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- Apply skin if available
  local skin = A.utilGui:GetElvUISkinModule()
  if skin then
    skin:HandleButton(b, true)
  end

  -- Show or hide based on options
  if A.options.addButtonToRaidTab then
    b:Show()
  else
    b:Hide()
  end

  R.raidTabButton = b
end

function M:OnEnable()
  M:RegisterEvent("PLAYER_ENTERING_WORLD",          refresh)
  M:RegisterEvent("GROUP_ROSTER_UPDATE",            refresh)
  M:RegisterEvent("CHAT_MSG_INSTANCE_CHAT",         watchChat)
  M:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER",  watchChat)
  M:RegisterEvent("CHAT_MSG_RAID",                  watchChat)
  M:RegisterEvent("CHAT_MSG_RAID_LEADER",           watchChat)
  M:RegisterEvent("CHAT_MSG_SAY",                   watchChat)
  M:RegisterEvent("CHAT_MSG_WHISPER",               watchChat)
  setupMinimapIcon()
  setupRaidTabButton()
end

function M:SetupTooltip(tooltip, isMinimapIcon)
  tooltip:ClearLines()
  if IsInGroup() then
    tooltip:AddDoubleLine(A.NAME, A.group:GetComp(A.util.GROUP_COMP_STYLE.ICONS_FULL))
  else
    tooltip:AddLine(A.NAME)
  end
  if A.sorter:IsPaused() then
    tooltip:AddLine(" ")
    tooltip:AddLine(A.util:Highlight(A.sorter:GetPausedSortMode()))
  end
  tooltip:AddLine(" ")
  tooltip:AddDoubleLine(L["phrase.mouse.clickLeft"], L["tooltip.right.fixRaid"]..":", 1,1,1, 1,1,0)
  tooltip:AddDoubleLine(" ", A.sortModes:GetDefault().name, 1,1,1, 1,1,0)
  tooltip:AddLine(" ")
  tooltip:AddDoubleLine(L["phrase.mouse.clickMiddle"], L["tooltip.right.split"], 1,1,1, 1,1,0)
  tooltip:AddLine(" ")
  tooltip:AddDoubleLine(L["phrase.mouse.clickRight"], TOOLTIP_RIGHT_GUI, 1,1,1, 1,1,0)
  if isMinimapIcon then
    tooltip:AddLine(" ")
    tooltip:AddDoubleLine(L["phrase.mouse.drag"], L["tooltip.right.moveMinimapIcon"], 1,1,1, 1,1,0)
  end
  if A.DEBUG >= 1 then
    tooltip:AddLine(" ")
    tooltip:AddLine("DEBUG group rebuild stats:")
    A.group:DebugGetStats(function(caller, count) tooltip:AddDoubleLine("  "..tostring(caller), count) end)
  end
  tooltip:Show()
end

function M:OnDisable()
  M:Refresh()
end

function M:ButtonPress(button)
  handleClick(button)
end

function M:FlashRaidTabButton()
  A.utilGui:OpenRaidTab()
  if R.flashTimer or not A.options.addButtonToRaidTab then
    return
  end
  local count = NUM_FLASHES * 2
  local function flash()
    count = count - 1
    if count % 2 == 0 then
      R.raidTabButton:UnlockHighlight()
    else
      R.raidTabButton:LockHighlight()
    end
    if count > 0 then
      R.flashTimer = M:ScheduleTimer(flash, DELAY_FLASH)
    else
      R.flashTimer = false
    end
  end
  flash()
end

local function setUI(buttonText, iconTexture)
  R.iconLDB.icon = iconTexture
  R.raidTabButton:SetText(L[buttonText])
  if buttonText == "button.fixRaid.text" then
    R.raidTabButton:Enable()
  else
    R.raidTabButton:Disable()
  end
end

function M:Refresh()
  A.frGui:Refresh()
  if not M:IsEnabled() then
    R.icon:Hide(A.NAME)
    R.raidTabButton:Hide()
    return
  end
  if A.sorter:IsProcessing() then
    if time() % 2 == 0 then
      setUI("button.fixRaid.working.text", CUBE_ICON_0)
    else
      setUI("button.fixRaid.working.text", CUBE_ICON_1)
    end
  elseif A.sorter:IsPaused() then
    setUI("button.fixRaid.paused.text", CUBE_ICON_BW)
  elseif A.util:IsLeader() then
    setUI("button.fixRaid.text", "Interface\\GROUPFRAME\\UI-Group-LeaderIcon")
  elseif A.util:IsLeaderOrAssist() then
    setUI("button.fixRaid.text", "Interface\\GROUPFRAME\\UI-GROUP-ASSISTANTICON")
  else
    setUI("button.fixRaid.text", CUBE_ICON_1)
  end
  if A.options.showMinimapIconAlways or (A.options.showMinimapIconPRN and A.util:IsLeaderOrAssist()) then
    R.icon:Show(A.NAME)
  else
    R.icon:Hide(A.NAME)
  end
  if A.options.addButtonToRaidTab then
    R.raidTabButton:Show()
  else
    R.raidTabButton:Hide()
  end
end
