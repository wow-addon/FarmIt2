--------------------------------------------------------------------------------
--  CORE FUNCTIONS
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
--  STARTUP
--------------------------------------------------------------------------------

-- return uptime information
-- threshold should be given in seconds
function FI_Uptime( threshold )
	local uptime = time() - FI_LOAD_TS;
	
	if threshold then
		-- check uptime against a given threshold
		if (uptime < threshold) then
			return false;
		else
			return true;
		end
	
	else
		return uptime;
	end
end

function FI_Init()
	-- determine load status
	if (FI_SV_CONFIG == nil) 
		or (FI_SVPC_CONFIG == nil) 
		or (FI_SVPC_STYLE == nil) 
		or (FI_SV_DATA == nil) 
		or (FI_SVPC_DATA == nil) 
		or (FI_SVPC_CACHE == nil) 
	then
		-- new install or something wrong with saved vars
		FI_STATUS = 1;
	elseif (FI_SV_CONFIG.version == nil) then
		-- sanity check on previous version number
		FI_STATUS = 2;
	elseif (FI_VERSION > FI_SV_CONFIG.version) then
		-- addon updated since last run
		FI_STATUS = 2;
		-- check minimum compatible version
		if (FI_SV_CONFIG.version < FI_MIN_VERSION) then
			FI_REQUIRES_REBUILD = true;
		end
	elseif (FI_SVPC_CONFIG.version == nil) or (FI_VERSION > FI_SVPC_CONFIG.version) then
		-- addon updated since last time this character played
		FI_STATUS = 2;
	else
		-- normal startup
		FI_STATUS = 3;
	end

	-- status responses
	if (FI_STATUS == 1) then
		FI_DB.rebuild("all");
		
	elseif (FI_STATUS == 2) then
		if FI_REQUIRES_REBUILD then
			FI_DB.rebuild("all");
		elseif FI_REQUIRES_RESET then
			FI_Reset();
		elseif FI_REBUILD_CONFIG then
			FI_DB.rebuild("config");
		else
			-- if no maintenance is required, just update the version number
			FI_SV_CONFIG.version = FI_VERSION;
			FI_SVPC_CONFIG.version = FI_VERSION;
		end
		
	elseif (FI_STATUS == 3) then
		-- all clear
	end
	
	-- validate configuration tables
	FI_DB.scan("recursive", FI_DEFAULTS.SV.CONFIG, FI_SV_CONFIG, true);
	FI_DB.scan("recursive", FI_DEFAULTS.SVPC.CONFIG, FI_SVPC_CONFIG, true);
end

----->>  FRAME CREATION  <<-----
function FI_Render()
	-- misc frames
	FI_FRAMES.Currency();
	
	-- loop through groups and build buttons
	for i,group in ipairs(FI_SVPC_DATA.Groups) do
		FI_FRAMES.Group(group.id);
	end
	FI_Scale();
	
	-----  SKIN  -----
	FI_Style();

	-----  SHOW  -----
	if (FI_SVPC_CONFIG.show == true) then
		_G["FI_PARENT"]:Show();
	else 
		_G["FI_PARENT"]:Hide();
	end
end

----->>  LOAD DATA  <<-----
function FI_Load()
	-- session start
	FI_SESSION.load();
	
	-- internal garbage collection
	FI_DB.garbage("logs");
	
	-- currency startup checks
	FI_Init_Currency();
	
	-- populate item buttons
	for i,button in ipairs(FI_SVPC_DATA.Buttons) do
		if button.item then
			FI_Set_Button(button.id);
		end
	end
	
	----- G2G, BUFF AND PULL! -----
	local version = "v"..tostring(FI_VERSION);
	if (FI_RELEASE ~= "RELEASE") then version = version.." "..FI_RELEASE; end
	local load_msg = "|cFF33CCFF".."FarmIt "..version.." "..FI_LOAD_STATES[FI_STATUS]..".  |cFFFFFFFF".."Type /farmit for configuration help.";
	
	-- indicate debug state
	if FI_SV_CONFIG.debug then 
		load_msg = load_msg.."\n|cFFFF0000Debugging output enabled!|r";
	end
	
	DEFAULT_CHAT_FRAME:AddMessage(load_msg);
end

function FI_Reset()
	if FI_SV_CONFIG.debug then print("[FarmIt]  RESET CALLED!"); end

	FI_DB.rebuild("config");
	FI_DB.rebuild("style");
	FI_DB.rebuild("frames");
	FI_DB.rebuild("currencies");
	FI_DB.rebuild("sessions");
	
	-- User initiated reset?
	if (FI_LOADING == false) then
		ReloadUI();
	end

	if FI_SV_CONFIG.debug then print("[FarmIt]  RESET COMPLETE."); end
end

--------------------------------------------------------------------------------
--  FRAME CREATION
--------------------------------------------------------------------------------
FI_FRAMES = {};

FI_FRAMES.Group = function( gid )
	if FI_SV_CONFIG.debug then print("Load routine running for Group ID: "..gid); end
	
	local group = FI_DB.select(FI_SVPC_DATA.Groups, {id = gid}, true);
	local f_name = "FI_Group_"..group.id;

	-- check if frame already exists
	if not _G[f_name] then
		-- create the base "anchor" frame for the bar
		local f = CreateFrame("Button", f_name, _G["FI_PARENT"], "FI_TPL_Group");
		f:SetFrameStrata("LOW");
		f:SetPoint("CENTER", UIParent, "CENTER", 0,0);
		f:SetScale(group.scale);
		-- visibility
		if group.show then f:Show(); else f:Hide(); end
		-- clicks
		f:EnableMouse(true);
		f:SetMovable(true);
		f:SetClampedToScreen(true);
		f:RegisterForClicks("LeftButtonDown","LeftButtonUp","RightButtonUp");
		f:SetScript("OnClick", FI_Click_Group);
		
		-- handle orientation related requirements
		local a = FI_SVPC_STYLE.anchor;
		local size_x,size_y,bg_size_x,bg_size_y;
		
		local vertical = {"U","D"};
		if tContains(vertical, group.grow) then
			-- vertical
			size_x,size_y = a.size[1],a.size[2];
			bg_size_x,bg_size_y = a.background.size[1],a.background.size[2];
		else
			-- horizontal
			size_x,size_y = a.size[2],a.size[1];
			bg_size_x,bg_size_y = a.background.size[2],a.background.size[1];
		end
		_G[f_name]:SetSize(size_x, size_y);
		_G[f_name.."_Background"]:SetSize(bg_size_x, bg_size_y);
		_G[f_name.."_Background"]:SetPoint("CENTER", _G[f_name], "CENTER", 0,-1);
		
		-- bar number
		_G[f_name.."_Label"]:SetFont(a.text.font, a.text.size, a.text.flags);
		_G[f_name.."_Label"]:SetPoint("CENTER", _G[f_name.."_Background"], "CENTER", 0,-6);
		_G[f_name.."_Label"]:SetText( FI_DB.find(FI_SVPC_DATA.Groups, {id = group.id}, true) );
		_G[f_name.."_Label"]:SetJustifyH("CENTER");
		_G[f_name.."_Label"]:SetJustifyV("MIDDLE");
		
		-----  POPULATE THE GROUP  ---------------------------------------------
		FI_FRAMES.Button(group.id);
		------------------------------------------------------------------------

		-- apply quicksize
		FI_UI_Button(group.id);

	else
		if FI_SV_CONFIG.debug then print("WARNING: Frame '"..f_name.."' already exists!"); end
	end
end

-- button, button, who's got the button...
FI_FRAMES.Button = function( gid )
	if FI_SV_CONFIG.debug then print("...loading buttons for Group ID: "..gid); end

	-- group frame is the first thing we anchor to
	local group = FI_DB.select(FI_SVPC_DATA.Groups, {id = gid}, true);
	local parent = _G["FI_Group_"..group.id];
	local last_frame = parent;
	local a = FI_SVPC_STYLE.anchor;
	local b = FI_SVPC_STYLE.button;
	
	for i,button in ipairs(FI_SVPC_DATA.Buttons) do
		-- group filter
		if (button.group == group.id) then
			-- define the frame name
			local f_name = "FI_Button_"..button.id;

			-- skip creation if frame exists (ie- adding buttons to an existing bar)
			if not _G[f_name] then
				local f = CreateFrame("Button", f_name, parent, "FI_TPL_Button");
				f:SetFrameStrata("LOW");
				f:Show();
				f:SetClampedToScreen(false);
				-- clicks
				f:RegisterForClicks("LeftButtonUp","RightButtonUp");
				f:SetScript("OnMouseUp", FI_Click);
				-- secure template attributes
				f:SetAttribute("type2", "macro");
				f:SetAttribute("macro", false);
				
				-- no padding for first button so it sits against the anchor
				if (last_frame == parent) then pad = a.pad; else pad = b.pad; end
				
				-- determine orientation
				local a1,a2,x,y;
				if (group.grow == "U") then
					-- bar grows up
					a1,a2,x,y = "BOTTOM","TOP",0,pad;
				elseif (group.grow == "D") then
					-- bar grows down
					a1,a2,x,y = "TOP","BOTTOM",0,-pad;
				elseif (group.grow == "L") then
					-- bar grows left
					a1,a2,x,y = "RIGHT","LEFT",-pad,0;
				elseif (group.grow == "R") then
					-- bar grows right
					a1,a2,x,y = "LEFT","RIGHT",pad,0;
				end

				-- position the frame
				f:SetPoint(a1, last_frame, a2, x, y);
				
				-- size
				_G[f_name.."_Background"]:SetSize(b.background.size[1], b.background.size[2]);

				--if FI_SV_CONFIG.debug then print("Button ID: "..button.id.." (Group ID: "..group.id..")"); end
			else
				if FI_SV_CONFIG.debug then print("Frame '"..f_name.."' already exists... skipping. (Group ID: "..group.id..")"); end
			end

			-- dynamic relative anchoringggggggggggg
			last_frame = f_name;
		end
	end
end

FI_FRAMES.Currency = function()
	if FI_SV_CONFIG.debug then print("FI_FRAMES.Currency called."); end
	
	-- set some script triggers
	_G["TokenFrameContainer"]:SetScript("OnHide", FI_Update_Currency);
	
	for n=1,3 do
		_G["BackpackTokenFrameToken"..n]:SetScript("OnMouseUp", FI_Edit_Currency);
	end
	
	GameTooltip:HookScript("OnShow", FI_Hook_Currency);
	
	-- floating currency bar (added in v2.22)
	if (not _G["FI_Currency"]) then
		local f_name = "FI_Currency";
		local a = FI_SVPC_STYLE.anchor;
		
		-- create the parent frame
		local f = CreateFrame("Button", f_name, _G["FI_PARENT"]);
		f:SetSize(175,22);
		f:SetFrameStrata("LOW");
		f:SetPoint("TOP", UIParent, "TOP", 0,-30);
		f:SetScale(FI_SVPC_CONFIG.Currency.scale);
		f:SetAlpha(FI_SVPC_CONFIG.Currency.alpha);
		f:Show();
		
		-- clicks
		f:SetMovable(true);
		f:SetClampedToScreen(true);
		
		-- background
		local bg = f:CreateTexture(f_name.."_Background", "BACKGROUND");
		bg:SetAllPoints(f);
		bg:SetTexture("Interface/Tooltips/UI-Tooltip-Background");
		bg:SetVertexColor(0,0,0);
		bg:SetAlpha(0.5);
		bg:Hide();
		
		local slots = {};
		
		for cid=1,3 do
			local slot_name = f_name.."_"..cid;
			
			-- create child frame
			slots[cid] = CreateFrame("Button", slot_name, _G[f_name]);
			local s = slots[cid];
			s:SetSize(50,18);
			s:Show();
			
			-- tooltip
			s:SetScript("OnEnter", FI_Tooltip_Currency);
			s:SetScript("OnLeave", GameTooltip_Hide);
			
			-- clicks
			s:EnableMouse(true);
			s:RegisterForClicks("LeftButtonDown","LeftButtonUp","RightButtonUp");
			s:SetScript("OnClick", FI_Click_Currency);
			
			-- background
			local bg = s:CreateTexture(slot_name.."_Background", "BACKGROUND");
			bg:SetAllPoints(s);
			bg:SetTexture("Interface/Tooltips/UI-Tooltip-Background");
			bg:SetVertexColor(0,0,0);
			bg:SetAlpha(0.5);
			bg:Hide();
			
			-- icon
			local i = s:CreateTexture(slot_name.."_Icon", "ARTWORK");
			i:SetSize(18,16);

			-- count
			local c = s:CreateFontString(slot_name.."_Count", "OVERLAY");
			c:SetFont(a.text.font, a.text.size, "OUTLINE");
			c:SetAlpha(a.text.alpha);
			c:SetJustifyH("RIGHT");
			c:SetJustifyV("MIDDLE");
			
			-- objective
			--[[
			local o = s:CreateFontString(slot_name.."_Objective", "OVERLAY");
			o:SetFont(a.text.font, a.text.size, "OUTLINE");
			o:SetAlpha(a.text.alpha);
			o:SetJustifyH("RIGHT");
			o:SetJustifyV("MIDDLE");
			]]
			
			-- position
			i:SetPoint("RIGHT", _G[slot_name], "RIGHT", 0,0);
			c:SetPoint("RIGHT", i, "LEFT", -2,0);
			--o:SetPoint("RIGHT", i, "LEFT", -2,16);
		end
		
		slots[1]:SetPoint("LEFT", _G[f_name], "LEFT", 2,0);
		slots[2]:SetPoint("CENTER", _G[f_name], "CENTER", 0,0);
		slots[3]:SetPoint("RIGHT", _G[f_name], "RIGHT", -2,0);
	end
end

--------------------------------------------------------------------------------
--  VISUAL STYLES
--------------------------------------------------------------------------------
function FI_Set_Texture( texture, arg )
	if (type(arg) == "table") then
		_G[texture]:SetTexture("Interface/BUTTONS/WHITE8X8");
		_G[texture]:SetVertexColor(arg[1], arg[2], arg[3]);
	elseif strlen(arg) then
		_G[texture]:SetTexture(arg);
	elseif FI_SV_CONFIG.debug then
		print("[FI_Set_Texture]  Bad texture data."); --debug
	end
end

function FI_Style( newstyle ) --wrapper
	if newstyle then
		-- validate input
		if FI_STYLES[newstyle] then
			-- update style data
			FI_SVPC_STYLE = LIB.table.copy(FI_STYLES[newstyle]);

			-- user feedback
			if (FI_LOADING == false) then
				FI_Message("'"..newstyle.."' visual style applied.");
			end
		else
			-- error message
			local list = "";
			for key,val in pairs(FI_STYLES) do list = list.."  "..key; end
			FI_Message("Style '"..newstyle.."' not found. Available options are: "..list);
			return;
		end
	end

	-- apply visual theme to all bars
	for i,group in ipairs(FI_SVPC_DATA.Groups) do
		FI_Group_Style(group.id);
	end
	
	-- apply style to currency frames
	FI_Currency_Style();
	
	-- master alpha setting
	_G["FI_PARENT"]:SetAlpha(FI_SVPC_CONFIG.alpha);
end

-- apply visual theme settings to a bar
function FI_Group_Style( gid )
	local group = FI_DB.select(FI_SVPC_DATA.Groups, {id = gid}, true);
	
	-- [ANCHOR] --------------------------------------------------
	local a = FI_SVPC_STYLE.anchor;
	local f_name = "FI_Group_"..group.id;
	
	_G[f_name]:SetAlpha(group.alpha);
	
	-- background
	FI_Set_Texture(f_name.."_Background", a.background.texture);
	_G[f_name.."_Background"]:SetAlpha(a.background.alpha);
	_G[f_name.."_Background"]:SetSize(a.background.size[1], a.background.size[2]);
	
	-- border
	
	-- label
	_G[f_name.."_Label"]:SetFont(a.text.font, a.text.size, a.text.flags);
	_G[f_name.."_Label"]:SetVertexColor(a.text.color[1], a.text.color[2], a.text.color[3]);
	_G[f_name.."_Label"]:SetAlpha(a.text.alpha);
	_G[f_name.."_Label"]:SetJustifyH("CENTER");
	_G[f_name.."_Label"]:SetJustifyV("MIDDLE");

	-- [BUTTON] --------------------------------------------------
	local b = FI_SVPC_STYLE.button;
	
	for i,bid in ipairs(FI_Group_Members(group.id)) do
		local button = FI_DB.select(FI_SVPC_DATA.Buttons, {id = bid}, true);
		f_name = "FI_Button_"..button.id;
		
		-- background
		FI_Set_Texture(f_name.."_Background", b.background.texture);
		_G[f_name.."_Background"]:SetAlpha(b.background.alpha);
		_G[f_name.."_Background"]:SetSize(b.background.size[1], b.background.size[2]);
		
		-- border
		
		-- glow
		FI_Set_Texture(f_name.."_Glow", b.glow.color);
		_G[f_name.."_Glow"]:SetAlpha(b.glow.alpha);
		
		-- numbers
		_G[f_name.."_Count"]:SetFont(b.number.font, b.number.size, b.number.flags);
		_G[f_name.."_Count"]:SetVertexColor(b.number.color[1], b.number.color[2], b.number.color[3]);
		_G[f_name.."_Count"]:SetAlpha(b.number.alpha);
		
		_G[f_name.."_Objective"]:SetFont(b.number.font, b.number.size, b.number.flags);
		_G[f_name.."_Objective"]:SetVertexColor(b.number.color[1], b.number.color[2], b.number.color[3]);
		_G[f_name.."_Objective"]:SetAlpha(b.number.alpha);

		-- [text]
	end
end

function FI_Currency_Style()
	local b = FI_SVPC_STYLE.button;
	
	for cid=1,3 do
		local f_name = "FI_Currency_"..cid;
		
		if _G[f_name] then
			-- background
			FI_Set_Texture(f_name.."_Background", b.background.texture);
			_G[f_name.."_Background"]:SetAlpha(b.background.alpha);
			
			-- numbers
			_G[f_name.."_Count"]:SetFont(b.number.font, b.number.size, b.number.flags);
			_G[f_name.."_Count"]:SetVertexColor(b.number.color[1], b.number.color[2], b.number.color[3]);
			_G[f_name.."_Count"]:SetAlpha(b.number.alpha);
			
			--[[
			_G[f_name.."_Objective"]:SetFont(b.number.font, b.number.size, b.number.flags);
			_G[f_name.."_Objective"]:SetVertexColor(b.number.color[1], b.number.color[2], b.number.color[3]);
			_G[f_name.."_Objective"]:SetAlpha(b.number.alpha);
			]]
			
		elseif FI_SV_CONFIG.debug then
			print("[FI_Currency_Style]  Frame '"..f_name.."' does not exist!"); --debug
		end
	end
end

--------------------------------------------------------------------------------
--  OUTPUT
--------------------------------------------------------------------------------
function FI_Alert( message, color, sound, throttle )
	-- control when output is allowed
	if (FI_LOADING == false) and (FI_MOVING == false) and (FI_Uptime(FI_MIN_UPTIME) == true) then
		if FI_SV_CONFIG.debug then print("FI_Alert called."); end
		
		-- spam filter
		local filter = false;
		if throttle and ((time() - FI_ALERT_TS) < FI_SPAM_LIMIT) then
			filter = true;
		end
		
		if filter then
			if FI_SV_CONFIG.debug then print("[FI_Alert]  Spam filter triggered."); end
		else
			-- audio
			if sound and FI_SV_CONFIG.Alerts.sound then
				PlaySound(sound);
			end

			-- chat frame
			if FI_SV_CONFIG.Alerts.chat then
				FI_Message(message, color);
			end
			
			-- on-screen
			if FI_SV_CONFIG.Alerts.screen then
				FI_Announce(message, color);
			end
		end
	end
	
	-- update timestamp
	FI_ALERT_TS = time();
end

-- wrapper for handling multi-line output
function FI_Message( message, color, msg_type )
	if (type(message) == "table") then
		for i,msg in pairs(message) do
			FI_Msg(msg, color, msg_type);
		end
	else
		FI_Msg(message, color, msg_type);
	end
end

-- color = table of R,G,B values and the hex code of the color
function FI_Msg( message, color, msg_type )
	local output;
	
	-- format message
	local prefix = "|cFF33CCFF[FarmIt]|r  ";
	
	if msg_type then
		if (msg_type == "debug") then
			prefix = prefix.."|cFFFFCC00<DEBUG>|r  ";
		elseif (msg_type == "error") then
			prefix = prefix.."|cFFFF3300ERROR:|r  ";
		end
	end
	
	if color then
		output = prefix.."|cFF"..color[4]..message;
	else
		output = prefix..message;
	end
	
	-- display message
	DEFAULT_CHAT_FRAME:AddMessage(output);
end

function FI_Announce( message, color )
	-- display announcement
	if color then
		UIErrorsFrame:AddMessage(message, color[1], color[2], color[3]);
	else
		UIErrorsFrame:AddMessage(message);
	end
end

--------------------------------------------------------------------------------
--  PROGRESS TRACKING
--------------------------------------------------------------------------------
function FI_Find_ByBag( bag, item )
	-- build list of items to check against
	local contents = {};
	for slot=1,GetContainerNumSlots(bag) do
		local id = GetContainerItemID(bag, slot);
		if id then table.insert(contents, id); end
	end
	
	if tContains(contents, item) then
		if FI_SV_CONFIG.debug then print("[FI_Find_ByBag]  Found item ID "..item.." in bag "..bag); end
		return true;
	else 
		if FI_SV_CONFIG.debug then print("[FI_Find_ByBag]  Item ID "..item.." not found in bag "..bag); end
		return false;
	end
end

function FI_Contents( bag )
	if FI_SV_CONFIG.debug then print("[FI_Contents] Called."); end
	
	local contents = {};
	
	for slot=1,GetContainerNumSlots(bag) do
		local id = GetContainerItemID(bag, slot);
		if id then table.insert(contents, id); end
	end
	
	if FI_SV_CONFIG.debug then table.dump(contents); end
	
	return contents;
end

-- NOTE: 
--   Because this function is called as a result of a BAG_UPDATE event, this code is executed AFTER the item has 
--   actually been added/removed from your bags. Therefore, the item count wont get updated if you no longer 
--   have any on hand because FI_Contents() wont find any in your bags...
function FI_Update( bagID )
	-- "smart item update" method bypassed for now, due to the problem described above (fixed in v2.22)
	if bagID and false then
		-- get list of all item IDs in the container
		local items = FI_Contents(bagID);
		
		-- check query results
		if (#items > 0) then
			if FI_SV_CONFIG.debug then print("[FI_Update] Selective update triggered."); end
			
			for i,button in ipairs(FI_SVPC_DATA.Buttons) do
				-- filter empty buttons
				if button.item then
					-- do we have any of the item in this container?
					if tContains(items, button.item) then
						-- if one of the items in the container is being tracked, run a proper update on it
						FI_Update_Button(nil, button);
					end
				end
			end
		else
			FI_Update_All();
		end
	else
		FI_Update_All();
	end
	
	-- update currencies because only 'BAG_UPDATE' fires when you *spend* points
	FI_Update_Currency();
end

-- global item update
function FI_Update_All()
	if FI_SV_CONFIG.debug then print("[FI_Update_All] Called."); end
	
	-- update all populated item slots
	for i,button in ipairs(FI_SVPC_DATA.Buttons) do
		if button.item then
			FI_Update_Button(nil, button);
		end
	end
end

function FI_Progress( data, silent )
	-- VERBOSE DEBUG
	if FI_SV_CONFIG.debug then print("[FI_Progress]  Called."); end
	
	local f_name,database,currencyName,status,info,suffix,color,sound,itemName,itemLink;
	
	if FI_SV_CONFIG.debug and true then
		if data then
			local item_msg
			if data.item then item_msg = data.item; elseif data.name then item_msg = data.name; else item_msg = "?"; end
			print("[FI_Progress]  Progress tracking triggered.  Item: "..item_msg..", Last Count: "..data.lastcount..", Count: "..data.count..", Objective: "..data.objective); --debug
		else
			print("[FI_Progress]  No data record was passed!"); return; --debug
		end
	end
	
	-- determine whether checking a button frame, or other type of data
	if data.item then
		f_name = "FI_Button_"..data.id;
		database = "Buttons";
		itemName,itemLink = GetItemInfo(data.item);
	elseif data.name then
		f_name = "FI_Currency_"..data.id;
		database = "Currencies";
		currencyName = "|cFF"..FI_SV_CONFIG.Colors.currency[4]..data.name.."|r";
	elseif FI_SV_CONFIG.debug then
		print("[FI_Progress]  Missing data!  f_name = "..f_name); return; --debug
	end
	
	-- gained, or lost?
	status = "Item update:";
	if (data.count > data.lastcount) then
		-- increase
		suffix = "(|cFF00FF00+"..data.count - data.lastcount.."|r)";
		sound = "igBackPackCoinSelect";
	elseif (data.count < data.lastcount) then
		-- decrease
		suffix = "(|cFFFF0000-"..data.lastcount - data.count.."|r)";
	else
		-- count has not changed
		if data.name then
			-- enforce objective state
			local suc;
			if (data.count < data.objective) then
				suc = false;
			else
				suc = true;
			end
			data = FI_DB.update(FI_SVPC_DATA[database], {id = data.id}, {success = suc});
			
			-- apply visual changes, if any
			FI_UI_Currency();
			
			-- prevent notification spam since currency updates are hooked to an onShow event.
			return;
		end
		
		suffix = "";
	end

	-- OBJECTIVE PROGRESS
	if (data.objective > 0) then
		if (data.count > data.lastcount) then
			status = "Farming progress:";
		else
			status = "Farming update:";
		end
		
		-- find out where things stand in relation to the objective
		if (data.count < data.objective) then
			color = FI_SV_CONFIG.Colors.objective;
			
			-- reset notification flag
			if (data.success == true) then
				data = FI_DB.update(FI_SVPC_DATA[database], {id = data.id}, {success = false});
			end
			
		elseif (data.success == false) then
			------------------------------------------------------------
			-- OBJECTIVE SUCCESS
			------------------------------------------------------------
			color = FI_SV_CONFIG.Colors.success;
			status = "Objective complete!";
			sound = "QUESTCOMPLETED";

			-- update notification flag
			data = FI_DB.update(FI_SVPC_DATA[database], {id = data.id}, {success = true});
			
		else
			-- greater than objective, already notified of success
			color = FI_SV_CONFIG.Colors.success;
			
			-- check notification flag
			if (data.success == false) then
				data = FI_DB.update(FI_SVPC_DATA[database], {id = data.id}, {success = true});
			end
		end
		
		------------------------------------------------------------
		-- UPDATE THE INTERFACE
		------------------------------------------------------------
		if (database == "Currencies") then
			_G[f_name.."_Count"]:SetVertexColor(color[1], color[2], color[3]);
		else
			_G[f_name.."_Objective"]:SetVertexColor(color[1], color[2], color[3]);
		end
		
		-- format notification message
		local hud = "|cFF"..color[4]..data.count.."/"..data.objective.."|r";
		if data.item then
			if itemLink then
				info = itemLink.."  "..hud;
			elseif FI_SV_CONFIG.debug then
				print("[FI_Progress]  Missing itemLink! (obj)"); --debug
			end
		elseif data.name then
			info = currencyName.."  "..hud;
		elseif FI_SV_CONFIG.debug then
			print("[FI_Progress]  Objective notification failed!"); --debug
		end
		
	-- STANDARD PROGRESS
	else
		color = FI_SV_CONFIG.Colors.progress;
		
		-- format message
		local hud = "|cFF"..color[4].."x "..data.count.."|r";
		if data.item then
			if itemLink then
				info = itemLink.."  "..hud;
			elseif FI_SV_CONFIG.debug then
				print("[FI_Progress]  Missing itemLink!"); --debug
			end
		elseif data.name then
			info = currencyName.."  "..hud;
		elseif FI_SV_CONFIG.debug then
			print("[FI_Progress]  Progress notification failed!"); --debug
		end
	end
	
	------------------------------------------------------------
	-- NOTIFICATION
	------------------------------------------------------------
	if info and (not silent) and (not CursorHasItem()) then
		local message = status.."  "..info.."  "..suffix;
		FI_Alert(message, nil, sound);
	end
	
	------------------------------------------------------------
	-- LOGGING
	------------------------------------------------------------
	local log_entry = {};
	log_entry["timestamp"] = time(); --seconds since "epoch"
	log_entry["table"] = database;
	log_entry["record_id"] = data.id;
	if data.item then
		log_entry["item"] = data.item;
		log_entry["count"] = GetItemCount(data.item);
	elseif data.name then
		log_entry["name"] = data.name;
		log_entry["count"] = data.count;
	elseif FI_SV_CONFIG.debug then
		print("[FI_Progress]  Log insert error."); --debug
	end
	table.insert(FI_SV_DATA.Log, log_entry);

	if FI_SV_CONFIG.debug and false then
		print("Progress tracking complete.  Item ID: "..data.item..", Last Count: "..data.lastcount..", Count: "..data.count..", Objective: "..data.objective); --debug
	end
end

-- (string) table name, (num) record id, (num) objective amount
function FI_Set_Objective( tbl_name, rec_id, amount )
	local data = FI_DB.select(FI_SVPC_DATA[tbl_name], {id = rec_id}, true);
	local f_name;
	
	-- capture input
	if amount then
		if FI_SV_CONFIG.debug then print("[FI_Set_Objective]  Table: "..tbl_name..",  ID: "..rec_id..",  Amount: "..amount); end
		
		if (amount == data.objective) then
			-- do nothing, input matches current objective
			if FI_SV_CONFIG.debug then print("[FI_Set_Objective]  Duplicate objective.  Input: "..amount..", Current Objective: "..data.objective); end
		else
			-- store new objective
			data = FI_DB.update(FI_SVPC_DATA[tbl_name], {id = data.id}, {objective = amount});
		end
		
		if data.name then
			-- update the cache
			FI_DB.cache(FI_SVPC_DATA, "Currencies");
		end
	end
	
	-- update grapical interface if necessary
	if data.item then
		f_name = "FI_Button_"..data.id;

		if (data.objective > 0) then
			_G[f_name.."_Objective"]:Show();
		else
			_G[f_name.."_Objective"]:Hide();
		end
	
	elseif data.name then
		--[[
		f_name = "FI_CurrencyBar_"..data.id;

		if (data.objective > 0) then
			_G[f_name]:Show();
		else
			_G[f_name]:Hide();
		end
		]]
	
	elseif FI_SV_CONFIG.debug then
		print("[FI_Set_Objective]  Missing data!"); return;
	end
	
	-- update interface
	if data.item then
		local precision;
		if (string.len(data.objective) > 5) then
			precision = 0;
		else
			precision = 1;
		end
		_G[f_name.."_Objective"]:SetText(LIB.ShortNum(data.objective,precision,4));
	end
	
	-- check progress
	FI_Progress(data, true);
	
	-- notify user
	if amount then
		local message,sound;
		local color = {1,1,1,"FFFFFF"};
		
		if (data.objective > 0) then
			-- build message
			if data.item then
				-- items
				local itemName, itemLink = GetItemInfo(data.item);
				if itemLink then
					message = "Farming objective set:  "..data.objective.." "..itemLink;
				elseif FI_SV_CONFIG.debug then
					print("[FI_Set_Objective]  Notification failed due to missing itemLink! Item ID: "..data.item); --debug
				end
			elseif data.name then
				-- currencies
				message = "Farming objective set:  "..data.objective.." "..data.name;
				
				-- update the cache
				FI_DB.cache(FI_SVPC_DATA, "Currencies");
			else
				print("[FI_Set_Objective]  Notification failed!"); --exception
			end
			
			-- decide which sound to use
			if (data.count > data.objective) then
				sound = "QUESTCOMPLETED";
			else
				sound = "QUESTADDED";
			end
		else
			-- inform user we are erasing an objective
			if data.success then
				message = "Farming objective removed.";
				sound = false;
			else
				message = "Farming objective abandoned.";
				sound = "igQuestLogAbandonQuest";
			end
		end
		
		FI_Alert(message, color, sound);
	end
end

function FI_Edit_Objective( bid )
	-- hide other edit boxes
	for i,b in ipairs(FI_SVPC_DATA.Buttons) do
		_G["FI_Button_"..b.id.."_Edit"]:Hide();
	end

	local button = FI_DB.select(FI_SVPC_DATA.Buttons, {id = bid}, true);
	local f_name = "FI_Button_"..button.id;

	-- set editbox to current value
	_G[f_name.."_Edit"]:SetText(button.objective);

	-- show editbox
	_G[f_name.."_Edit"]:Show();
	_G[f_name.."_Edit"]:HighlightText();
end

function FI_Clear_Objective( bid )
	local f_name = "FI_Button_"..bid;
	local color = FI_SV_CONFIG.Colors.objective;

	-- reset objective related data
	local button = FI_DB.update(FI_SVPC_DATA.Buttons, {id = bid}, {objective = 0, success = false});

	-- reset graphical elements
	_G[f_name.."_Objective"]:SetText("");
	_G[f_name.."_Objective"]:SetVertexColor(color[1], color[2], color[3]);
	_G[f_name.."_Objective"]:Hide();
end
