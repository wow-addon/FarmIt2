--------------------------------------------------------------------------------
--  BAR/BUTTON VISUAL STYLES
--
--  "Fonts/FRIZQT__.TTF"
--  "Fonts/ARIALN.TTF"
--  Interface\CHATFRAME\ChatFrameBorder.blp
--------------------------------------------------------------------------------
--[[

To make your own graphical theme for FarmIt:

	1) Edit/add a template in FarmIt2_Style.lua
	2) Reload your interface for the changes to be available: /reloadui
	3) Type: "/farmit style templatename" to load your new theme into memory.
	4) If necessary, reload your interface again to save/apply the changes: /reloadui

]]
--------------------------------------------------------------------------------

FI_STYLES = {};

--------------------------------------------------------------------------------
-- DEFAULT
-- Matches the stock WoW interface.
--------------------------------------------------------------------------------
FI_STYLES["default"] = {
	["anchor"] = {
		["size"] = {34,34},
		["pad"] = 2,
		["background"] = {
			--texture = "Interface/Buttons/UI-Quickslot",
			texture = "Interface/BUTTONS/UI-QuickSlot",
			size = {56,56},
			color = {},
			alpha = 0.75,
		},
		["border"] = {
			texture = "",
			tile = true,
			size = 6,
			offset = 2,
			color = {},
			alpha = 1,
		},
		["text"] = {
			font = "Fonts/ARIALN.TTF",
			size = 13,
			flags = "OUTLINE",
			color = {1,1,1},
			alpha = 1,
		},
	},
	
	["button"] = {
		["size"] = {37,37},
		["pad"] = 5,
		["background"] = {
			texture = "Interface/BUTTONS/UI-EmptySlot.blp",
			size = {66,66},
			color = {},
			alpha = 0.75,
		},
		["border"] = {
			texture = "",
			tile = true,
			size = 6,
			offset = 2,
			alpha = 0.9,
		},
		["glow"] = {
			color = {0.3,0.3,0.3},
			alpha = 0.9,
		},
		["number"] = {
			font = "Fonts/ARIALN.TTF",
			size = 14,
			flags = "OUTLINE",
			color = {1,1,1},
			alpha = 1,
		},
		["text"] = {
			font = "Fonts/FRIZQT__.TTF",
			size = 14,
			flags = "OUTLINE",
			color = {0.5,0.5,0.5},
			alpha = 0.75,
		},
	},
}


--------------------------------------------------------------------------------
-- MINIMAL
-- Clean style, goes better with mods like Bartender.
--------------------------------------------------------------------------------
FI_STYLES["minimal"] = {
	["anchor"] = {
		["size"] = {34,34},
		["pad"] = 0,
		["background"] = {
			texture = {"Interface/Tooltips/UI-Tooltip-Background"},
			size = {34,32},
			color = {0,0,0},
			alpha = 0.5,
		},
		["border"] = {
			texture = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			size = 6,
			offset = 2,
			color = {},
			alpha = 0.9,
		},
		["text"] = {
			font = "Fonts/ARIALN.TTF",
			size = 13,
			flags = "",
			color = {1,1,1},
			alpha = 1,
		},
	},
	
	["button"] = {
		["size"] = {37,37},
		["pad"] = 4,
		["background"] = {
			texture = {0,0,0},
			size = {36,36},
			color = {},
			alpha = 0.66,
		},
		["border"] = {
			texture = "Interface/Tooltips/UI-Tooltip-Border",
			tile = true,
			size = 6,
			offset = 2,
			color = {},
			alpha = 0.9,
		},
		["icon"] = {
			texture = "",
			color = {},
			alpha = 1,
		},
		["glow"] = {
			texture = "Interface/CHATFRAME/CHATFRAMEBACKGROUND",
			color = {1,1,0},
			alpha = 0.5,
		},
		["number"] = {
			font = "Fonts/ARIALN.TTF",
			size = 14,
			flags = "OUTLINE",
			color = {1,1,1},
			alpha = 1,
		},
		["text"] = {
			font = "Fonts/FRIZQT__.TTF",
			size = 28,
			flags = "OUTLINE",
			color = {0.5,0.5,0.5},
			alpha = 0.75,
		},
	},
}
