--[[----------------------------------------------------------------------------
	BUTTON CODE
	
	inherits="ItemButtonTemplate"

	The goal of this code is to have the item buttons be autonomous units,
	allowing the mod to be as flexible as possible.
	
	Button tooltips use localized information labels from FarmIt2_Locales.lua
		[1] = "Item Level",
		[2] = "Stack Size",
		[3] = "Item ID",
		
		[4] = "Button ID",
		[5] = "Count",
		[6] = "Stacks",
		[7] = "Objective",
		[8] = "Include Bank",
		[9] = "Objective Complete",
	
]]------------------------------------------------------------------------------

-- ITEM SLOT TOOLTIPS
function FI_Tooltip( self )
	-- allow user to disable item slot tooltips
	if (FI_SV_CONFIG.Tooltips.button == false) then return; end
	
	-- get the button id
	local bid = FI_FrameToID( self:GetName() );

	if FI_SV_CONFIG.debug then print("You hovered button ID: "..bid); end

	-- db queries
	local button = FI_DB.select(FI_SVPC_DATA.Buttons, {id = bid}, true);
	local bar = FI_DB.select(FI_SVPC_DATA.Groups, {id = button.group}, true);
	
	-- determine where to attach the tooltip
	local anchor,x,y;
	if (bar.grow == "U") then
		anchor = "ANCHOR_TOP";
		x,y = 0,16;
	elseif (bar.grow == "D") then
		anchor = "ANCHOR_BOTTOM";
		x,y = 0,-16;
	elseif (bar.grow == "L") then
		anchor = "ANCHOR_LEFT";
		x,y = -8,0;
	elseif (bar.grow == "R") then
		anchor = "ANCHOR_RIGHT";
		x,y = 8,0;
	end
	
	GameTooltip:SetOwner(self, anchor, x,y);
	
	-- BUILD TOOLTIP
	if button.item then
		local spacer = ":  ";
		
		-- extra item info
		local sName, sLink, iQuality, iLevel, iMinLevel, sType, sSubType, iStackSize = GetItemInfo(button.item);
		if sLink then
			GameTooltip:SetHyperlink(sLink);
			
			-- check for iTip
			if IsAddOnLoaded("iTip") then
				-- let iTip do this part (prevents duplicate info)
			else
				GameTooltip:AddLine("\n"..sType.." ("..sSubType..")");
				GameTooltip:AddLine(FI_LABELS[2]..spacer..iStackSize, 1,1,1);
				GameTooltip:AddLine(FI_LABELS[1]..spacer..iLevel, 1,1,1);
				GameTooltip:AddLine(FI_LABELS[3]..spacer..button.item, 1,1,1);
			end
		else
			-- either API query failed, or there's a bad (manually entered) item id
			GameTooltip:AddLine("(error)");
			GameTooltip:AddLine(FI_LABELS[3]..spacer..button.item, 1,1,1);
		end
		
		-- FarmIt info
		GameTooltip:AddLine("\n|cFF33CCFF"..FI_LABELS[4]..spacer..button.id, 1,1,1);
		
		local counts = FI_LABELS[5]..spacer..button.count;
		if iStackSize and (iStackSize > 1) then
			local stacks = LIB.round((button.count/iStackSize),2);
			counts = counts.."  ("..stacks.." "..FI_LABELS[6]..")";
		end
		GameTooltip:AddLine(counts, 1,1,1);
		
		if (button.objective > 0) then
			GameTooltip:AddLine(FI_LABELS[7]..spacer..button.objective, 1,1,1);
		end
		GameTooltip:AddLine(FI_LABELS[8]..spacer..strupper(tostring(button.bank)));
		if (button.objective > 0) then
			GameTooltip:AddLine(FI_LABELS[9]..spacer..strupper(tostring(button.success)));
		end
		
		GameTooltip:AddLine("_________________________________\n", 0.33,0.33,0.33);
		
		-- show button help text
		local help_text = {
			"|cFF00FF00Click|r to select/move an item.",
			"|cFF00FF00Shift+Click|r toggles bank inclusion.",
			"|cFF00FF00Ctrl+Click|r to set a farming objective.",
			"|cFF00FF00Right-Click|r to USE the item.",
			"|cFF00FF00Shift+Right-Click|r clears the slot.",
			"|cFF00FF00Ctrl+Right-Click|r to enter an Item ID."
		};
		GameTooltip:AddLine(help_text[1], 1,1,1);
		GameTooltip:AddLine(help_text[2], 1,1,1);
		GameTooltip:AddLine(help_text[3], 1,1,1);
		GameTooltip:AddLine(help_text[4], 1,1,1);
		GameTooltip:AddLine(help_text[5], 1,1,1);
		GameTooltip:AddLine(help_text[6], 1,1,1);
		
		-- all done!
		GameTooltip:Show();
	end
end

function FI_Select( bid )
	-- copy to "clipboard"
	FI_SELECTED = bid;

	PlaySound("igAbilityIconPickup");

	-- selection indicator
	_G["FI_Button_"..FI_SELECTED.."_Glow"]:Show();

	if FI_SV_CONFIG.debug then print("Button ID #"..bid.." SELECTED for moving..."); end
end

-- pass true to disable sound
function FI_Deselect( mute )
	-- turn off selection indicator
	_G["FI_Button_"..FI_SELECTED.."_Glow"]:Hide();

	-- clear the "clipboard"
	FI_SELECTED = false;

	if not mute then
		PlaySound("igAbilityIconDrop");
	end
end

-- added in v2.0 beta2
function FI_Move_Item( bid1, bid2 )
	FI_MOVING = true;
	
	local source = FI_DB.select(FI_SVPC_DATA.Buttons, {id = bid1}, true);
	local target = FI_DB.select(FI_SVPC_DATA.Buttons, {id = bid2}, true);
	
	-- move the selected button data
	if FI_SV_CONFIG.debug then print("FI_Move_Item:  Moving ItemID "..source.item); end
	FI_DB.copy(FI_SVPC_DATA.Buttons, {id = source.id}, {id = target.id}); --preserves the primary key ("id" field)
	-- make sure the destination button keeps its *group* id
	FI_DB.update(FI_SVPC_DATA.Buttons, {id = target.id}, {group = target.group}); --do NOT update variable!
	
	-- load new button data in destination (target) slot
	FI_Set_Button(target.id);
	
	-- clear original (source) button
	FI_Clear_Button(source.id);
	
	-- swapping contents with a populated button?
	if target.item then
		if FI_SV_CONFIG.debug then print("FI_Move_Item:  Swapping places with ItemID "..target.item); end
		
		-- get table index of source button
		local index = FI_DB.find(FI_SVPC_DATA.Buttons, {id = source.id}, true);
		
		-- copy target button data over source button
		FI_SVPC_DATA.Buttons[index] = LIB.table.copy(target);
		-- keep the original IDs so things dont get all discombobulated (technical term)
		FI_SVPC_DATA.Buttons[index]["id"] = source.id;
		FI_SVPC_DATA.Buttons[index]["group"] = source.group;
		
		-- load button data
		FI_Set_Button(source.id);
	end
	
	FI_Deselect();
	
	FI_MOVING = false;
end

--------------------------------------------------------------------------------
--  CLICK HANDLER
--------------------------------------------------------------------------------
function FI_Click( self, click, down )
	local f_name = self:GetName();
	if FI_SV_CONFIG.debug then print("You CLICKED the "..click.." ("..tostring(down)..") on frame: "..f_name); end
	
	local button = FI_DB.select(FI_SVPC_DATA.Buttons, {id = FI_FrameToID(f_name)}, true);
	
	if CursorHasItem() then
		------------------------------------------------------------
		-- NEW ITEM
		------------------------------------------------------------
		local itemType, itemID, itemLink = GetCursorInfo();
		if (itemType == "item") then
			-- save new item to button record
			button = FI_DB.update(FI_SVPC_DATA.Buttons, {id = button.id}, {item = itemID});
			-- apply data to slot
			FI_Set_Button(button.id);
			-- clear item from cursor
			ClearCursor();
		end
	
	elseif (click == "LeftButton") then
		if _G["FI_Button_Edit_Item"] then _G["FI_Button_Edit_Item"]:Hide(); end
		
		if IsShiftKeyDown() then
			------------------------------------------------------------
			-- INCLUDE BANK
			------------------------------------------------------------
			FI_Toggle_Bank(button.id);
		
		elseif IsControlKeyDown() then
			------------------------------------------------------------
			-- SET OBJECTIVE
			------------------------------------------------------------
			FI_Edit_Objective(button.id);
		
		elseif FI_SELECTED then
			------------------------------------------------------------
			-- MOVE
			------------------------------------------------------------
			if (button.id == FI_SELECTED) then
				-- cancel the selection (same slot was clicked)
				FI_Deselect();
			else
				FI_Move_Item(FI_SELECTED, button.id);
			end
		
		elseif button.item then
			------------------------------------------------------------
			-- SELECT ITEM
			------------------------------------------------------------
			FI_Select(button.id);
		end
	
	elseif (click == "RightButton") then
		if IsShiftKeyDown() then
			------------------------------------------------------------
			-- CLEAR SLOT
			------------------------------------------------------------
			if button.item then
				FI_Clear_Button(button.id);
				PlaySound("gsTitleOptionOK");
			end
		
		elseif IsControlKeyDown() then
			------------------------------------------------------------
			-- MANUAL ITEM ENTRY
			------------------------------------------------------------
			FI_Edit_Item(self, button);
		
		else
			------------------------------------------------------------
			-- USE ITEM
			------------------------------------------------------------
			-- Right-click "use" action on actual item is handled by SecureActionButton_OnClick()
			-- See FarmIt2_Button.xml, FI_FRAMES.Button, and FI_Set_Button
			if button.item then
				-- make sure we actually have the item in our inventory
				if GetItemSpell(button.item) and (GetItemCount(button.item) > 0) then
					-- inform user that Right-Click action was received
					local itemName, itemLink = GetItemInfo(button.item);
					if itemLink then
						FI_Message("Using "..itemLink);
					end
				end
			end
		end
	end
	-- /mouse buttons
end

--------------------------------------------------------------------------------
--  ITEM RELATED STUFF
--------------------------------------------------------------------------------
function FI_Set_ItemCount( input )
end

function FI_Update_Button( bid, db_record )
	local button;
	
	-- streamline button data access when we are doing a global update
	if db_record then
		button = db_record;
	else
		button = FI_DB.select(FI_SVPC_DATA.Buttons, {id = bid}, true);
	end
	
	if button.item then
		if FI_SV_CONFIG.debug and (FI_LOADING == false) and false then
			print("Update running... ButtonID: "..button.id..", ItemID: "..button.item..", Count: "..button.count); --debug
		end
		local f_name = "FI_Button_"..button.id;
		
		--------------------------------------------------------------------------------
		--  CHECK FOR FAILED SERVER QUERIES
		--------------------------------------------------------------------------------
		-- attempt to fix missing icons
		if not _G[f_name.."_Icon"]:GetTexture() then
			if FI_SV_CONFIG.debug then print("Update found a missing texture on BID "..button.id); end
			
			_G[f_name.."_Icon"]:SetTexture( GetItemIcon(button.item) );
		end
		
		-- make sure secure template action has been set
		if not _G[f_name]:GetAttribute("macrotext") then
			if FI_SV_CONFIG.debug then print("Update found missing macrotext on BID "..button.id); end
			
			local itemName = GetItemInfo(button.item);
			if itemName then
				_G[f_name]:SetAttribute("macrotext", "/use "..itemName);
			end
		end
		
		--------------------------------------------------------------------------------
		-- GET CURRENT ITEM COUNT
		--------------------------------------------------------------------------------
		local newcount = GetItemCount(button.item, button.bank);
		
		-- try to be smart about only running interface and data changes when we need to
		if FI_LOADING or FI_MOVING or (newcount ~= button.count) then
			--------------------------------------------------------------------------------
			-- SAVE NEW ITEM COUNT
			--------------------------------------------------------------------------------
			local query = {
				["count"] = newcount,
				["lastcount"] = button.count,
			}
			button = FI_DB.update(FI_SVPC_DATA.Buttons, {id = button.id}, query);
			
			-- update graphical counter
			_G[f_name.."_Count"]:SetText( LIB.ShortNum(button.count,1,4) );
			
			--------------------------------------------------------------------------------
			--  PROGRESS TRACKING
			--------------------------------------------------------------------------------
			FI_Progress(button);
		end
		
	else
		-- no item, clear the count
		_G["FI_Button_"..button.id.."_Count"]:SetText("");
	end
end

function FI_Set_Button( bid, newItem )
	local button;
	
	-- update itemID before setting button elements
	if newItem then
		FI_Clear_Button(bid);
		button = FI_DB.update(FI_SVPC_DATA.Buttons, {id = bid}, {item = newItem});
	else
		button = FI_DB.select(FI_SVPC_DATA.Buttons, {id = bid}, true);
	end
	
	if button.item then
		local f_name = "FI_Button_"..button.id;

		-- set icon
		_G[f_name.."_Icon"]:SetTexture( GetItemIcon(button.item) ); --if this fails, FI_Update_Button should fix it

		-- bank inclusion indicator
		if button.bank then
			_G[f_name.."_Bank"]:Show();
		end
		
		-- set secure template action
		local itemName, itemLink = GetItemInfo(button.item); --if this fails, FI_Update_Button should fix it
		if itemName then
			_G[f_name]:SetAttribute("macrotext", "/use "..itemName);
		end
		
		-- handle objective
		if (button.objective == 0) or CursorHasItem() then
			-- no objective -OR- we are in the middle of placing a new item
			FI_Clear_Objective(button.id);
		else
			-- there is an objective, apply it to the interface
			if (string.len(button.objective) > 5) then
				precision = 0;
			else
				precision = 1;
			end
			_G[f_name.."_Objective"]:SetText(LIB.ShortNum(button.objective,precision,4));
			
			local color;
			if (button.count < button.objective) then
				color = FI_SV_CONFIG.Colors.objective;
			else
				color = FI_SV_CONFIG.Colors.success;
			end
			
			_G[f_name.."_Objective"]:SetVertexColor(color[1], color[2], color[3]);
			_G[f_name.."_Objective"]:Show();
		end
		
		FI_Update_Button(nil, button);
		
		if FI_SV_CONFIG.debug then
			if itemLink then
				print( "FI_Set_Button:  Button ID "..button.id.." set to "..itemLink ); --debug
			else
				print( "FI_Set_Button:  Button ID "..button.id.." GetItemInfo FAILED!"); --debug
			end
		end
	end
end

function FI_Clear_Button( bid )
	local button = FI_DB.select(FI_SVPC_DATA.Buttons, {id = bid}, true);
	
	if button then
		-- reset button data
		local i = FI_DB.find(FI_SVPC_DATA.Buttons, {id = button.id}, true);
		FI_SVPC_DATA.Buttons[i] = LIB.table.copy(FI_DEFAULTS.DB.Button);
		-- preserve the ID's
		FI_SVPC_DATA.Buttons[i]["id"] = button.id;
		FI_SVPC_DATA.Buttons[i]["group"] = button.group;

		FI_Clear_Objective(button.id);
		
		if _G["FI_Button_Edit_Item"] then _G["FI_Button_Edit_Item"]:Hide(); end
		
		-- reset graphical elements
		local f_name = "FI_Button_"..button.id;
		_G[f_name.."_Icon"]:SetTexture("");
		_G[f_name.."_Count"]:SetText("");
		_G[f_name.."_Bank"]:Hide();
		
		-- clear secure template action
		_G[f_name]:SetAttribute("macrotext", nil);
	elseif FI_SV_CONFIG.debug then
		print( "FI_Clear_Button:  Button ID "..bid.." DB select query FAILED!"); --debug
	end
end

--------------------------------------------------------------------------------

-- allow manual entry of an item id. ie: if you dont have the item on you, but you want to check your bank, etc.
function FI_Edit_Item( self, button )
	local f_name = self:GetName();
	local eb_name = "FI_Button_Edit_Item";
	
	-- hide objective editboxes
	for i,b in ipairs(FI_SVPC_DATA.Buttons) do
		_G["FI_Button_"..b.id.."_Edit"]:Hide();
	end
	
	-- create item editbox if it doesn't exist yet
	if not _G[eb_name] then
		local f = CreateFrame("EditBox", eb_name, _G["FI_PARENT"], "FI_TPL_Editbox");
		f:SetSize(80,35);
		f:SetJustifyH("CENTER");
		f:SetClampedToScreen(true);
		-- tooltip
		f:SetScript("OnEnter", FI_Tooltip_Edit_Item);
		f:SetScript("OnLeave", GameTooltip_Hide);
		-- text entry
		f:SetScript("OnEnterPressed", FI_Set_Item);
		f:SetScript("OnEscapePressed", f.Hide);
		f:SetScript("OnEditFocusLost", f.Hide);
		f:SetMaxBytes(7);
		f:SetNumeric(true);
		f:SetAutoFocus(true);
		f:SetHistoryLines(10);
	end
	
	-- adjust anchoring as needed
	_G[eb_name]:SetParent(self);
	_G[eb_name]:SetPoint("TOP", self, "BOTTOM", 0, 0);
	
	-- populate editbox
	if button.item and (button.item > 0) then
		_G[eb_name]:SetNumber(button.item);
	else
		_G[eb_name]:SetNumber("");
	end
	
	_G[eb_name]:Show();
	_G[eb_name]:HighlightText();
end

function FI_Set_Item( editbox )
	local parent = editbox:GetParent();
	local bid = FI_FrameToID( parent:GetName() );
	
	-- get input
	local itemID = editbox:GetNumber();
	if itemID and (itemID > 0) then
		-- process item id
		FI_Set_Button(bid, itemID);
	end
	
	editbox:Hide();
end

function FI_Tooltip_Edit_Item( self )
	-- build tooltip
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT");
	GameTooltip:AddLine("Enter a numeric Item ID...", 1,1,1);
	GameTooltip:Show();
end

--------------------------------------------------------------------------------
--  BANK INVENTORY
--------------------------------------------------------------------------------
function FI_Toggle_Bank( bid )
	local button = FI_DB.select(FI_SVPC_DATA.Buttons, {id = bid}, true);
	local f_name = "FI_Button_"..button.id;
	
	if button.item then
		-- change setting
		button = FI_DB.update(FI_SVPC_DATA.Buttons, {id = button.id}, {bank = LIB.toggle(button.bank)});
		
		-- bank indicator
		if button.bank then
			_G[f_name.."_Bank"]:Show();
		else
			_G[f_name.."_Bank"]:Hide();
		end
		
		-- refresh item count
		FI_Update_Button(button.id);
		
		PlaySound("TalentScreenClose");
		FI_Message("Button ID "..button.id..":  Include Bank = "..strupper(tostring(button.bank)));
	end
end
