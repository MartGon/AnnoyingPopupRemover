-- module_undercut.lua
-- Written by KyrosKrane Sylvanblade (kyros@kyros.info)
-- Copyright (c) 2020 KyrosKrane Sylvanblade
-- Licensed under the MIT License, as per the included file.
-- Addon version: @project-version@

-- This file defines a module that APR can handle. Each module is one setting or popup.

-- This module removes the help tip popup telling you that you no longer need to undercut when posting items on the AH.

-- Grab the WoW-defined addon folder name and storage table for our addon
local _, APR = ...

-- Upvalues for readability
local DebugPrint = APR.Utilities.DebugPrint
local MakeString = APR.Utilities.MakeString
local L = APR.L


--#########################################
--# Module settings
--#########################################

-- Note the lowercase naming of modules. Makes it easier to pass status and settings around
local ThisModule = "undercut"

-- Set up the module
APR.Modules[ThisModule] = {}

-- the name of the variable in APR.DB and its default value
APR.Modules[ThisModule].DBName = "HideUndercut"
APR.Modules[ThisModule].DBDefaultValue = APR.SHOW_DIALOG

-- This is the config setup for AceConfig
APR.Modules[ThisModule].config = {
	name = L["Hide the reminder that undercutting is no longer required when selling at the auction house"],
	type = "toggle",
	set = function(info,val) APR:HandleAceSettingsChange(val, info) end,
	get = function(info) return APR.DB.HideUndercut end,
	descStyle = "inline",
	width = "full",
} -- config

-- Set the order based on the file inclusion order in the TOC
APR.Modules[ThisModule].config.order = APR.NextOrdering
APR.NextOrdering = APR.NextOrdering + 10

-- These are the status strings that are printed to indicate whether it's off or on
APR.Modules[ThisModule].hidden_msg = L[ThisModule .. "_hidden"]
APR.Modules[ThisModule].shown_msg = L[ThisModule .. "_shown"]

-- This Boolean tells us whether this module works in Classic.
APR.Modules[ThisModule].WorksInClassic = false


-- This function handles the function that shows the AH help tooltip.
local function ControlAHUndercutPopup()
	if APR.DB.HideUndercut then
		-- Replace with a blank function
		DebugPrint("in '" .. ThisModule .. "' ControlAHUndercutPopup(), replacing ShowHelpTip with dummy")
		_G["AuctionHouseFrame"].CommoditiesSellFrame.ShowHelpTip = function() end
		_G["AuctionHouseFrame"].ItemSellFrame.ShowHelpTip = function() end
	else
		-- Restore the default function
		DebugPrint("in '" .. ThisModule .. "' ControlAHUndercutPopup(), restoring default ShowHelpTip")
		_G["AuctionHouseFrame"].CommoditiesSellFrame.ShowHelpTip = APR.StoredDialogs["C_ShowHelpTip"]
		_G["AuctionHouseFrame"].ItemSellFrame.ShowHelpTip = APR.StoredDialogs["I_ShowHelpTip"]
	end
end


-- This function causes the popup to show when triggered.
APR.Modules[ThisModule].ShowPopup = function(printconfirm)
	DebugPrint("in APR.Modules['" .. ThisModule .. "'].ShowPopup, printconfirm is " .. MakeString(printconfirm))

	-- Mark that the popup is shown.
	APR.DB.HideUndercut = APR.SHOW_DIALOG

	-- Show it immediately in case the AH is already open
	ControlAHUndercutPopup()

	if printconfirm then APR:PrintStatus(ThisModule) end
end -- ShowPopup()


-- This function causes the popup to be hidden when triggered.
APR.Modules[ThisModule].HidePopup = function(printconfirm, ForceHide)
	DebugPrint("in APR.Modules['" .. ThisModule .. "'].HidePopup, printconfirm is " .. MakeString(printconfirm ) .. ", ForceHide is " .. MakeString(ForceHide))

	-- Mark that the popup is hidden.
	APR.DB.HideUndercut = APR.HIDE_DIALOG

	-- Hide it immediately in case the AH is already open
	ControlAHUndercutPopup()

	if printconfirm then APR:PrintStatus(ThisModule) end
end -- HidePopup()


-- This function executes before the addon has fully loaded. Use it to initialize any settings this module needs.
-- This function can be safely deleted if not used by this module.
APR.Modules[ThisModule].PreloadFunc = function()
	-- Ensure the AH UI is loaded
	LoadAddOn("Blizzard_AuctionHouseUI")

	-- Store the default help tip function
	-- Note that unlike the other dialogs, this one is always stored.
	-- This isn't strictly a dialog, but thanks to lua's flexibility, we can stuff it in here just the same!
	APR.StoredDialogs["C_ShowHelpTip"] = _G["AuctionHouseFrame"].CommoditiesSellFrame.ShowHelpTip
	APR.StoredDialogs["I_ShowHelpTip"] = _G["AuctionHouseFrame"].ItemSellFrame.ShowHelpTip

	-- Hook the AH to always call our function when it's shown
	DebugPrint("in APR.Modules['" .. ThisModule .. "'].PreloadFunc, hooking SetAmount.")
	hooksecurefunc(_G["AuctionHouseFrame"].ItemSellFrame.PriceInput, "SetAmount", ControlAHUndercutPopup)
end -- PreloadFunc()
