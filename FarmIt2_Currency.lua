--------------------------------------------------------------------------------
--  CURRENCY RELATED FUNCTIONS
--[[
	'bar' = Bar Number
		The dynamic table index of a group's record in: FI_SVPC_DATA["Groups"]
		This is a user interface convention to provide the appearance of sequential bar numbers regardless of the actual group ID.
	
	'gid' = Group ID
		The numeric primary key of a group as found in its data "record" stored at FI_SVPC_DATA.Groups
	
	'bid' = Button ID
		The numeric primary key of a button as found in its data "record" stored at FI_SVPC_DATA.Buttons
	
	'cid' = Currency ID
		The numeric primary key of a "watched" currency as found in its data "record" stored at FI_SVPC_DATA.Currencies
	
	'sid' = Session ID
		The numeric primary key of a farming session as found in its data "record" stored at FI_SVPC_DATA.Sessions
]]--
--------------------------------------------------------------------------------

-- if currency name given, returns full info if available
function FI_HasTokens( currency )
	-- check if player has any trackable currencies available
	for index=1,GetCurrencyListSize() do
		local name, isHeader, isExpanded, isUnused, isWatched, count, icon, maximum, hasWeeklyLimit, currentWeeklyAmount = GetCurrencyListInfo(index);
		--print(GetCurrencyListSize().."    "..name.."    "..tostring(isHeader).."    "..count);
		
		-- NOTE: new characters start out with [Player vs. Player, Conquest Points = 0] 
		-- even though they have NO currency tab on their character window
		if name and (not isHeader) and (GetCurrencyListSize() > 2) then
			if currency then
				-- query matched, return item data
				if (currency == name) then
					return index, name, count, maximum, hasWeeklyLimit, currentWeeklyAmount;
				end
			else
				-- found a currency, exit loop
				return true;
			end
		end
	end
end

-- currency bootstrap
function FI_Init_Currency( event )
	if FI_SV_CONFIG.debug then print("[FI_Init_Currency]  Called."); end
	
	if FI_HasTokens() then
		-- register for "watch currency" updates
		_G["TokenFramePopupBackpackCheckBox"]:HookScript("OnClick", FI_Update_Currency);
		
		-- one-time startup check
		if (FI_CURRENCY_LOADED == false) then
			FI_DB.scan("Currencies");
		end
		
		FI_Update_Currency(event);
		
		FI_CURRENCY_LOADED = true;
	end
end

-- core currency update routine
function FI_Update_Currency( event )
	-- prevent extra calls curing startup
	if ((FI_LOADING == true) and (FI_CURRENCY_LOADED == true)) or ((FI_CURRENCY_LOADED == true) and (FI_Uptime(FI_MIN_UPTIME) == false)) then
		return;
	end
	
	if FI_SV_CONFIG.debug then print("[FI_Update_Currency]  Called."); end
	
	-- config check
	if (FI_SVPC_CONFIG.Currency.tracking == false) then
		if FI_SV_CONFIG.debug then print("[FI_Update_Currency]  Currency tracking is OFF."); end
		return;
	end
	
	-- take a snapshot of current data
	local temp = LIB.table.copy(FI_SVPC_DATA.Currencies);
	
	-- process DATA UPDATES for all three "watched currency" slots
	for cid=1,3 do
		-- API query
		local name,count,icon = GetBackpackCurrencyInfo(cid);
		
		local results;
		if name then
			-- server returned something for the current slot
			local query = {
				["name"] = name,
				["count"] = count,
				["icon"] = icon,
			}
			
			-- check for lastcount data in snapshot
			local existing = FI_DB.select(temp, {["name"] = name}, true);
			if existing then
				query["lastcount"] = existing.count;
			else
				query["lastcount"] = count;
			end

			-- check for cached objective data
			if FI_SVPC_CACHE.Currencies then
				local cached = FI_DB.select(FI_SVPC_CACHE.Currencies, {["name"] = name}, true);
				if cached then
					query["objective"] = cached.objective;
				else
					query["objective"] = 0;
					query["success"] = false;
				end
			end
			
			------------------------------------------------------------
			-- save updated record
			------------------------------------------------------------
			results = FI_DB.update(FI_SVPC_DATA.Currencies, {id = cid}, query);
		
		elseif (FI_LOADING == false) then
			------------------------------------------------------------
			-- clear unused "slot"
			------------------------------------------------------------
			results = FI_Clear_Currency(cid);
		
		else
			------------------------------------------------------------
			-- use existing data
			------------------------------------------------------------
			results = FI_DB.select(FI_SVPC_DATA.Currencies, {id = cid}, true);
		end
		
		------------------------------------------------------------
		-- progress tracking
		------------------------------------------------------------
		if (FI_LOADING == false) and (FI_SVPC_CONFIG.Currency.tracking == true) then
			FI_Progress(results);
		end
	end
	
	------------------------------------------------------------
	-- update interface
	------------------------------------------------------------
	FI_Update_Currency_Bar();
	FI_UI_Currency();
end

-- reset a currency "slot"
function FI_Clear_Currency( cid )
	if FI_SV_CONFIG.debug then print("[FI_Clear_Currency]  Called."); end

	-- get default data
	local query = LIB.table.copy(FI_DEFAULTS.DB.Currency);
	
	-- update record
	query.id = cid;
	local results = FI_DB.update(FI_SVPC_DATA.Currencies, {id = cid}, query);
	
	return results;
end

-- Currency Bar UI update wrapper
function FI_Update_Currency_Bar( currency )
	if FI_SV_CONFIG.debug then print("[FI_Update_Currency_Bar]  Called."); end

	-- update a specific slot
	if currency then
		FI_Update_Currency_Slot(currency);
	else
		-- update all 3 slots
		for cid=1,3 do
			local results = FI_DB.select(FI_SVPC_DATA.Currencies, {id = cid}, true);
			FI_Update_Currency_Slot(results);
		end
	end
end

-- update UI of a given slot on the currency bar
function FI_Update_Currency_Slot( currency )
	if FI_SV_CONFIG.debug then print("[FI_Update_Currency_Slot]  Called."); end

	local slot = "FI_Currency_"..currency.id;
	
	if (strlen(currency.name) > 0) then
		-- populate slot
		_G[slot.."_Icon"]:SetTexture(currency.icon);
		_G[slot.."_Count"]:SetText(currency.count);
		--_G[slot.."_Objective"]:SetText(currency.objective);
		_G[slot]:Show();
	else
		-- clear slot
		_G[slot.."_Icon"]:SetTexture("");
		_G[slot.."_Count"]:SetText("");
		--_G[slot.."_Objective"]:SetText("");
		_G[slot]:Hide();
	end
end

-- apply visual style rules
function FI_UI_Currency()
	if FI_SV_CONFIG.debug then print("[FI_UI_Currency]  Called."); end
	
	for cid=1,3 do
		local f_name = "FI_Currency_"..cid;
		local currency = FI_DB.select(FI_SVPC_DATA.Currencies, {id = cid}, true);
		
		if currency.name then
			local color = FI_SV_CONFIG.Colors.progress;
			if (currency.objective > 0) then
				if (currency.success) then
					color = FI_SV_CONFIG.Colors.success;
				else
					color = FI_SV_CONFIG.Colors.objective;
				end
			end
			
			_G[f_name.."_Count"]:SetVertexColor(color[1], color[2], color[3]);
			
			-- color the backpack token text
			local name,count,icon = GetBackpackCurrencyInfo(cid);
			if name then
				_G["BackpackTokenFrameToken"..cid].count:SetVertexColor(color[1], color[2], color[3]);
			end
			
			_G[f_name]:Show();
		else
			_G[f_name]:Hide();
		end
	end
	
	-- parent frame settings
	_G["FI_Currency"]:SetScale(FI_SVPC_CONFIG.Currency.scale);
	_G["FI_Currency"]:SetAlpha(FI_SVPC_CONFIG.Currency.alpha);
	
	if (FI_SVPC_CONFIG.Currency.show == true) then
		_G["FI_Currency"]:Show();
	
	elseif (FI_SVPC_CONFIG.Currency.show == false) then
		_G["FI_Currency"]:Hide();
	
	elseif (FI_SVPC_CONFIG.Currency.show == nil) then
		-- something wrong with config...
		if FI_SV_CONFIG.debug then 
			print("[FI_UI_Currency]  ERROR: Missing config variable!");
			--FI_SVPC_CONFIG.Currency = LIB.table.copy(FI_DEFAULTS.SVPC.CONFIG.Currency);
		end
	end
end

--------------------------------------------------------------------------------

-- FarmIt info for use in currency tooltips
function FI_Currency_Tooltip( cid )
	-- grab currency record for the slot
	local currency = FI_DB.select(FI_SVPC_DATA.Currencies, {id = cid}, true);
	
	local line = "";
	if currency.name and (currency.objective > 0) then
		-- set color
		local color;
		if (currency.count < currency.objective) then
			color = FI_SV_CONFIG.Colors.progress[4];
		else
			color = FI_SV_CONFIG.Colors.success[4];
		end
		
		line = "|nObjective: |cFF"..color..currency.objective.."|r|n";
	else
		
	end
	
	local hint = "|cFF00FF00Right-Click|cFFFFFFFF to set farming objective.|r";
	
	return line.."|n"..hint;
end

-- build Currency Bar tooltip
function FI_Tooltip_Currency( self )
	-- allow user to disable currency bar tooltips
	if (FI_SV_CONFIG.Tooltips.currency == false) then return; end

	local cid = FI_FrameToID( self:GetName() );
	local name = GetBackpackCurrencyInfo(cid);
	local index = FI_HasTokens(name);
	
	-- create tooltip
	GameTooltip:SetOwner(self,"ANCHOR_BOTTOMLEFT",50,-30);
	
	if name then
		-- insert the normal tooltip for this currency
		GameTooltip:SetCurrencyToken(index);
		-- insert FarmIt lines
		GameTooltip:AddLine(FI_Currency_Tooltip(cid).."|n|cFFFFFFFFHold |cFF00FF00Shift|cFFFFFFFF to move Currency Bar.|r");
	end
	
	GameTooltip:Show();
end

-- build Backpack tooltip
function FI_Hook_Currency( tooltip )
	if (FI_SVPC_CONFIG.Currency.tracking == true) and tooltip:GetOwner() then
		local owner = tooltip:GetOwner();
		
		-- THIS LINE CAUSES A TAINTED CODE ERROR WHEN USING BLIZZARD'S TWITTER INTEGRATION INTERFACE!!
		-- Try getting the parent frame's name right off instead of getting the whole object, and if it's not a backpack or currency window frame just exit.
		local parent = owner:GetParent();
		
		if parent and (parent:GetName() == "BackpackTokenFrame") then
			cid = tonumber(strsub(owner:GetName(), -1));
			-- show objective if set
			local line = FI_Currency_Tooltip(cid);
			if line then GameTooltip:AddLine(line);	tooltip:Show(); end
		end
	end
end

--------------------------------------------------------------------------------

function FI_Click_Currency( self, click, down )
	local f_name = self:GetName();
	if FI_SV_CONFIG.debug then print("You CLICKED the "..click.." ("..tostring(down)..") on frame: "..f_name); end
	
	-- config check
	if (FI_SVPC_CONFIG.Currency.tracking == false) then return; end
	
	if (click == "LeftButton") then
		local parent = "FI_Currency";
		
		if IsShiftKeyDown() then
			------------------------------------------------------------
			-- DRAG BAR
			------------------------------------------------------------
			if down then
				_G[parent]:StartMoving();
			else
				_G[parent]:StopMovingOrSizing();
			end
		
		else
			------------------------------------------------------------
			-- 
			------------------------------------------------------------
			if down then
				--
			else
				_G[parent]:StopMovingOrSizing();
			end
			
		end
	
	elseif (click == "RightButton") then
		if IsShiftKeyDown() then
			------------------------------------------------------------
			-- 
			------------------------------------------------------------
			
		else
			------------------------------------------------------------
			-- EDIT OBJECTIVE
			------------------------------------------------------------
			if down then
				--
			else
				FI_Edit_Currency(self, click, down);
			end
		end
	end
end

function FI_Edit_Currency( self, click, down )
	-- configuration check
	if (not FI_SVPC_CONFIG.Currency.tracking) then return; end
	
	if (click == "RightButton") then
		local f_name = self:GetName();
		local parent = self:GetParent();
		local cid;
		
		-- determine the slot id
		if (parent:GetName() == "BackpackTokenFrame") then
			cid = tonumber(strsub(f_name, -1)); --BackpackTokenFrameToken1
		else
			cid = FI_FrameToID(f_name); --FI_Currency_1
		end
		
		local eb_name = "FI_Currency_"..cid.."_Editbox";

		if FI_SV_CONFIG.debug then print("You CLICKED the "..click.." ("..tostring(down)..") on frame:  "..f_name); end
		
		-- hide existing editboxes
		for cid=1,3 do
			local eb_n = "FI_Currency_"..cid.."_Editbox";
			if _G[eb_n] then _G[eb_n]:Hide(); end
		end
		
		-- create editbox if it doesn't exist yet
		if not _G[eb_name] then
			local s = FI_SVPC_STYLE.anchor;
			
			local f = CreateFrame("EditBox", eb_name, parent, "FI_TPL_Editbox");
			f:SetSize(100,35);
			f:SetJustifyH("CENTER");
			f:SetPoint("TOP", _G["BackpackTokenFrameToken"..cid], "BOTTOM", 0, 0);
			
			f:SetScript("OnEnterPressed", FI_Set_Objective_Currency);
			f:SetScript("OnEscapePressed", f.Hide);
			f:SetScript("OnEditFocusLost", f.Hide);
			
			f:SetMaxBytes(8);
			f:SetNumeric(true);
			f:SetAutoFocus(true);
			f:SetHistoryLines(6);
		end
		
		-- adjust anchoring as needed
		_G[eb_name]:SetPoint("TOP", self, "BOTTOM", 0, 0);
		
		-- get current data
		local currency = FI_DB.select(FI_SVPC_DATA.Currencies, {id = cid}, true);
		
		-- update the interface
		if currency then
			_G[eb_name]:SetNumber(currency.objective);
			_G[eb_name]:Show();
			_G[eb_name]:HighlightText();
			--FI_Message("Enter a |cFF"..FI_SV_CONFIG.Colors.currency[4]..currency.name.."|r objective...");
		
		elseif FI_SV_CONFIG.debug then
			print("[FI_Edit_Currency]  DB query failed for 'cid':  "..cid); --debug
		end
	end
end

-- FI_Set_Objective wrapper
function FI_Set_Objective_Currency( editbox, id, input )
	local cid,amt;
	
	if editbox then
		cid = FI_FrameToID( editbox:GetName() );
		amt = editbox:GetNumber();
		
	elseif id and input then
		cid = tonumber(id);
		amt = tonumber(input);
		
	elseif FI_SV_CONFIG.debug then
		-- error
		print("[FI_Set_Objective_Currency]  Input error."); --debug
	end
	
	-- select record
	local currency = FI_DB.select(FI_SVPC_DATA.Currencies, {["id"] = cid}, true);
	
	if currency then
		-- skip updating if input matches current objective
		if (amt ~= currency.objective) then
			-- dew it!
			FI_Set_Objective("Currencies", currency.id, amt);
			FI_Update_Currency();
		
		elseif FI_SV_CONFIG.debug then
			print("[FI_Set_Objective_Currency]  Duplicate objective input, update skipped."); --debug
		end
			
	elseif FI_SV_CONFIG.debug then
		print("[FI_Set_Objective_Currency]  DB query failed for CID:  "..cid); --debug
	end
	
	--hide input frame
	editbox:Hide();
end

--------------------------------------------------------------------------------
--  MONEY TRACKING
--  This will be moved to it's own file once it is actually implemented.
--------------------------------------------------------------------------------
function FI_Money( event, arg )
	if FI_SV_CONFIG.debug then FI_Message("FI_Money:  "..event.."  "..arg); end
end

function FI_Update_Money( event, arg )
	if FI_SV_CONFIG.debug then FI_Message("FI_Update_Money:  "..event.."  "..arg); end
end
