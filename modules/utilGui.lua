--- Utility functions useful for defining GUIs. This addon uses AceGUI wherever
-- possible, but there are a number of use cases that AceGUI does not cover.
--
-- We implement these by modifying the WoW frame object, taking care to reverse
-- the modifications when done. The frames need to be in their original
-- condition when returned to the AceGUI pool.
--
-- These use cases are:
--  * Buttons with custom textures.
--  * Windows draggable by clicking anywhere, not just the title bar.
--  * Windows that capture the Escape key to close.
--
local A, L = unpack(select(2, ...))
local M = A:NewModule("utilGui", "AceTimer-3.0")
A.utilGui = M
M.private = {
  openRaidTabTimer = false,
}
local R = M.private

local FILL_PLUS_STATUS_BAR = A.NAME.."FillPlusStatusBar"
local DELAY_OPEN_RAID_TAB = 0.01
local AceGUI = LibStub("AceGUI-3.0")

local ChatFrame_OpenChat, GameFontHighlightLarge, GetCurrentKeyBoardFocus, GetBindingFromClick, InterfaceOptionsFrame, InterfaceOptionsFrame_OpenToCategory, IsAddOnLoaded, OpenFriendsFrame, PlaySound, ToggleFriendsFrame = ChatFrame_OpenChat, GameFontHighlightLarge, GetCurrentKeyBoardFocus, GetBindingFromClick, InterfaceOptionsFrame, InterfaceOptionsFrame_OpenToCategory, C_AddOns.IsAddOnLoaded, OpenFriendsFrame, PlaySound, ToggleFriendsFrame
local format, max, pairs, strmatch = format, max, pairs, strmatch

-- GLOBALS: ElvUI

function M:OpenRaidTab()
  if not R.openRaidTabTimer then
    -- In case we just called SetRaidSubgroup or SwapRaidSubgroup, add in a
    -- short delay to avoid confusing the Blizzard UI addon.
    R.openRaidTabTimer = M:ScheduleTimer(function()
      R.openRaidTabTimer = false
      OpenFriendsFrame(4)
    end, DELAY_OPEN_RAID_TAB)
  end
end

function M:ToggleRaidTab()
  ToggleFriendsFrame(3)
end

function M:OpenConfig()
  -- Use the new Settings API to open the specific category for your addon
  if Settings and Settings.OpenToCategory then
    local category = Settings.GetCategory(A.NAME)
    if category then
      Settings.OpenToCategory(A.NAME)
    else
      -- If for some reason the category isn't found, fall back to opening the settings menu
      Settings.OpenToCategory(Settings.Categories.Interface)
    end
  else
    -- Fallback for older versions or issues
    InterfaceOptionsFrame_OpenToCategory(A.NAME)
  end
end

function M:CloseConfig()
    -- Check if the config panel is shown and hide it using the newer method
    local panel = SettingsPanel or InterfaceOptionsFrame
    if panel and panel:IsShown() then
        panel:Hide()
    end
end

function M:InsertText(text)
  local editBox = GetCurrentKeyBoardFocus()
  if editBox then
    if not strmatch(editBox:GetText(), "%s$") then
      text = " "..text
    end
    editBox:Insert(text)
  else
    ChatFrame_OpenChat(text)
  end
end

function M:GetElvUISkinModule()
  if C_AddOns.IsAddOnLoaded("ElvUI") and ElvUI then
    local E = ElvUI[1]
    if E.private.skins.blizzard.enable and E.private.skins.blizzard.nonraid then
      return E:GetModule("Skins")
    end
  end
end

function M:AddTexturedButton(registry, button, style)
  if M:GetElvUISkinModule() then
    button.frame:SetNormalTexture(format("Interface\\Addons\\%s\\media\\button%sFlat.tga", A.NAME, style))
    button.frame:GetNormalTexture():SetTexCoord(0, 1, 0, 0.71875)
  else
    button.frame:SetNormalTexture(format("Interface\\Addons\\%s\\media\\button%sUp.tga", A.NAME, style))
    button.frame:GetNormalTexture():SetTexCoord(0, 1, 0, 0.71875)
    button.frame:SetHighlightTexture(format("Interface\\Addons\\%s\\media\\button%sHighlight.tga", A.NAME, style))
    button.frame:GetHighlightTexture():SetTexCoord(0, 1, 0, 0.71875)
  end
  registry[button] = true
end

--- Remove custom modifications done to frames owned by AceGUI.
function M:CleanupWindow(window, texturedButtonRegistry)
    if texturedButtonRegistry then
        for button, _ in pairs(texturedButtonRegistry) do
            texturedButtonRegistry[button] = nil
            button.frame:SetNormalTexture("")  -- Set to an empty string instead of nil
            button.frame:SetHighlightTexture("")
        end
    end
    window.frame:SetPropagateKeyboardInput(false)
    window.frame:SetScript("OnKeyDown", nil)
    window.frame:SetScript("OnDragStart", nil)
    window.frame:SetScript("OnDragStop", nil)
    window.frame:RegisterForDrag()
    window._CloseWithSound = nil
    window._SetStatusText = nil
end