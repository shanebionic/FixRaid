local addonName, addonTable = ...
local A = LibStub("AceAddon-3.0"):NewAddon(addonName)
A.NAME = addonName
A.VERSION_RELEASED = C_AddOns.GetAddOnMetadata(A.NAME, "Version")
A.VERSION_PACKAGED = gsub(C_AddOns.GetAddOnMetadata(A.NAME, "X-Curse-Packaged-Version") or A.VERSION_RELEASED, "^v", "")
A.AUTHOR = C_AddOns.GetAddOnMetadata(A.NAME, "Author")
A.DEBUG = 0 -- 0=off 1=on 2=verbose
A.DEBUG_MODULES = "*"  -- use comma-separated module names to filter
A.L = LibStub("AceLocale-3.0"):GetLocale(A.NAME)
addonTable[1] = A
addonTable[2] = A.L
_G[A.NAME] = A
