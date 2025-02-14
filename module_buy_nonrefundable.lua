-- module_buy_nonrefundable.lua
-- Written by KyrosKrane Sylvanblade (kyros@kyros.info)
-- Copyright (c) 2015-2021 KyrosKrane Sylvanblade
-- Licensed under the MIT License, as per the included file.
-- Addon version: @project-version@

-- This file defines a module that APR can handle. Each module is one setting or popup.

-- This module hides the popup when the user tries to buy an item from a vendor and the item is not refundable.

-- Grab the WoW-defined addon folder name and storage table for our addon
local addonName, APR = ...

-- Upvalues for readability
local DebugPrint = APR.Utilities.DebugPrint
local ChatPrint = APR.Utilities.ChatPrint
local MakeString = APR.Utilities.MakeString
local L = APR.L


--#########################################
--# Module settings
--#########################################

-- Note the lowercase naming of modules. Makes it easier to pass status and settings around
local ThisModule = "nonrefundable" -- old name buynonrefundable

-- Set up the module
APR.Modules[ThisModule] = {}

-- the name of the variable in APR.DB and its default value
APR.Modules[ThisModule].DBName = "HideBuyNonrefundable"
APR.Modules[ThisModule].DBDefaultValue = APR.HIDE_DIALOG

-- This is the config setup for AceConfig
APR.Modules[ThisModule].config = {
	name = L["Hide the confirmation pop-up when buying a nonrefundable item"],
	type = "toggle",
	set = function(info,val) APR:HandleAceSettingsChange(val, info) end,
	get = function(info) return APR.DB.HideBuyNonrefundable end,
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
APR.Modules[ThisModule].WorksInClassic = false;


-- This function causes the popup to show when triggered.
APR.Modules[ThisModule].ShowPopup = function(printconfirm)
	DebugPrint("in APR.Modules['" .. ThisModule .. "'].ShowPopup, printconfirm is " .. MakeString(printconfirm))

	if APR.DB.HideBuyNonrefundable then
		-- Re-enable the dialog for selling group-looted items to a vendor while still tradable.
		StaticPopupDialogs["CONFIRM_PURCHASE_NONREFUNDABLE_ITEM"] = APR.StoredDialogs["CONFIRM_PURCHASE_NONREFUNDABLE_ITEM"]
		APR.StoredDialogs["CONFIRM_PURCHASE_NONREFUNDABLE_ITEM"] = nil

		-- Mark that the dialog is shown.
		APR.DB.HideBuyNonrefundable = APR.SHOW_DIALOG

	-- else already shown, nothing to do.
	end

	if printconfirm then APR:PrintStatus(ThisModule) end
end -- ShowPopup()


-- This function causes the popup to be hidden when triggered.
APR.Modules[ThisModule].HidePopup = function(printconfirm, ForceHide)
	DebugPrint("in APR.Modules['" .. ThisModule .. "'].HidePopup, printconfirm is " .. MakeString(printconfirm ) .. ", ForceHide is " .. MakeString(ForceHide))

	if not APR.DB.HideBuyNonrefundable or ForceHide then
		-- Disable the dialog for selling group-looted items to a vendor while still tradable.
		APR.StoredDialogs["CONFIRM_PURCHASE_NONREFUNDABLE_ITEM"] = StaticPopupDialogs["CONFIRM_PURCHASE_NONREFUNDABLE_ITEM"]
		StaticPopupDialogs["CONFIRM_PURCHASE_NONREFUNDABLE_ITEM"] = nil

		-- Mark that the dialog is hidden.
		APR.DB.HideBuyNonrefundable = APR.HIDE_DIALOG

	-- else already hidden, nothing to do.
	end

	if printconfirm then APR:PrintStatus(ThisModule) end
end -- HidePopup()


-- This function force-buys an item pending in the merchant window if the option is enabled.
local function ForceBuyNonrefundableItem(SPU_Name, ...)
	DebugPrint("in ForceBuyNonrefundableItem, SPU_Name is " .. SPU_Name)
	if APR.DB.HideBuyNonrefundable and SPU_Name == "CONFIRM_PURCHASE_NONREFUNDABLE_ITEM" then
		DebugPrint("in ForceBuyNonrefundableItem, auto buying item")
		BuyMerchantItem(MerchantFrame.itemIndex, MerchantFrame.count)
	else
	   	DebugPrint("in ForceBuyNonrefundableItem, NOT auto buying item")
	end
end


-- Now hook the purchase function.
if not APR.IsClassic or APR.Modules[ThisModule].WorksInClassic then
	-- This function executes before the addon has fully loaded. Use it to initialize any settings this module needs.
	APR.Modules[ThisModule].PreloadFunc = function()
		-- Hook the function called when you try to buy an item with an alternate currency.
		-- This Blizz function calls the static dialog with the confirm option.
		hooksecurefunc("StaticPopup_Show", ForceBuyNonrefundableItem)
	end
end -- WoW Classic check
