--------------------------------------------------------------------------------
--  GROUP RELATED CODE
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

-- return all the button id's that belong to a specific group
function FI_Group_Members( gid )
	local results = {};
	
	for i,button in ipairs(FI_SVPC_DATA.Buttons) do
		if (button.group == gid) then
			table.insert(results, button.id);
		end
	end
	
	table.sort(results);
	return results;
end

function FI_Movable( gid )
	local group = FI_DB.select(FI_SVPC_DATA.Groups, {id = gid}, true);
	
	-- check both the global setting and individual bar setting
	if group.move and FI_SVPC_CONFIG.move then
		return true;
	else
		return false;
	end
end

function FI_Lock( bar, gid )
	local lockmsg = "locked", msg_pre;
	
	if gid then
		local group = FI_DB.select(FI_SVPC_DATA.Groups, {id = gid}, true);
		group = FI_DB.update(FI_SVPC_DATA.Groups, {id = gid}, {move = LIB.toggle(group.move)});
		msg_pre = "Bar "..tostring(group.id);
		if group.move then lockmsg = "unlocked"; end
	elseif bar then
		FI_SVPC_DATA.Groups[bar]["move"] = LIB.toggle( FI_SVPC_DATA.Groups[bar]["move"] );
		msg_pre = "Bar "..tostring(bar);
		if FI_SVPC_DATA.Groups[bar]["move"] then lockmsg = "unlocked"; end
	else
		-- toggle lock state of all bars at once
		FI_GlobalLock();
		msg_pre = "All bars";
		if FI_SVPC_CONFIG.move then lockmsg = "unlocked"; end
	end
	
	FI_Message(msg_pre..": position "..lockmsg..".");
end

function FI_Unlock( bar, gid )
	local msg_pre;
	
	if gid then
		local group = FI_DB.select(FI_SVPC_DATA.Groups, {id = gid}, true);
		group = FI_DB.update(FI_SVPC_DATA.Groups, {id = gid}, {move = true});
		msg_pre = "Bar "..tostring(group.id);
	elseif bar then
		FI_SVPC_DATA.Groups[bar]["move"] = LIB.toggle( FI_SVPC_DATA.Groups[bar]["move"] );
		msg_pre = "Bar "..tostring(bar);
	else
		-- set lock state of all bars at once
		FI_GlobalLock(false);
		msg_pre = "All bars";
	end
	
	FI_Message(msg_pre..": position unlocked.");
end

function FI_GlobalLock( setting )
	if (setting == nil) then
		-- toggle global flag
		FI_SVPC_CONFIG.move = LIB.toggle(FI_SVPC_CONFIG.move)
	else
		-- set global flag
		FI_SVPC_CONFIG.move = setting;
	end
	
	-- apply new global setting to all bars
	FI_DB.update(FI_SVPC_DATA.Groups, {id = "*"}, {move = FI_SVPC_CONFIG.move});
end

function FI_Tooltip_Group( self )
	-- allow user to disable anchor tooltip
	if (FI_SV_CONFIG.Tooltips.bar == false) then return; end
	
	local f_name = self:GetName();
	local gid = FI_FrameToID(f_name);
	
	-- db query
	local g = FI_DB.select(FI_SVPC_DATA.Groups, {id = gid}, true);
	
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT");
	GameTooltip.inherits = "GameFontNormalSmall";
	
	local bar_num = _G[f_name.."_Label"]:GetText();
	GameTooltip:AddLine("|cFF33CCFFFarmIt Bar #"..bar_num.."\n", 1,1,1);
	
	-- BAR SETTINGS INFO
	if FI_SV_CONFIG.debug then
		GameTooltip:AddLine("Show Bar:  "..strupper(tostring(g.show)));
	end
	
	local results = FI_DB.find(FI_SVPC_DATA.Buttons, {group = g.id});
	local num_slots = #(results);
	
	GameTooltip:AddLine("Total Slots:  "..tostring(num_slots));
	GameTooltip:AddLine("Slots Visible:  "..tostring(g.size));
	
	local str_grow;
	if (g.grow == "U") then str_grow = "Up";
	elseif (g.grow == "D") then str_grow = "Down";
	elseif (g.grow == "L") then str_grow = "Left";
	elseif (g.grow == "R") then str_grow = "Right"; end
	GameTooltip:AddLine("Grow:  "..str_grow);
	
	GameTooltip:AddLine("Scale:  "..tostring((g.scale * 100)).."%");
	GameTooltip:AddLine("Alpha:  "..tostring((g.alpha * 100)).."%");
	
	GameTooltip:AddLine("\nPosition Locked:  "..strupper(tostring(LIB.toggle(g.move))));
	GameTooltip:AddLine("_________________________________\n", 0.33,0.33,0.33);
	
	-- HELP TEXT
	local help_text = {
		"|cFF00FF00Click|r and drag to move the bar.",
		"|cFF00FF00Shift+Click|r to lock bar position.",
		"|cFF00FF00Right-Click|r opens the help page.",
		"|cFF00FF00Shift+Right-Click|r for config options."
	};
	GameTooltip:AddLine(help_text[1], 1,1,1);
	GameTooltip:AddLine(help_text[2], 1,1,1);
	GameTooltip:AddLine(help_text[3], 1,1,1);
	GameTooltip:AddLine(help_text[4], 1,1,1);
	
	-- all done!
	GameTooltip:Show();
end

function FI_Click_Group( self, click, down )
	local f_name = self:GetName();
	if FI_SV_CONFIG.debug then print("You CLICKED the "..click.." ("..tostring(down)..") on frame: "..f_name); end

	local group = FI_DB.select(FI_SVPC_DATA.Groups, {id = FI_FrameToID(f_name)}, true);

	if (click == "LeftButton") then
		if IsShiftKeyDown() then
			------------------------------------------------------------
			-- LOCK POSITION
			------------------------------------------------------------
			if (down == false) then
				FI_Lock(nil,group.id);
			end
		
		else
			------------------------------------------------------------
			-- DRAG BAR
			------------------------------------------------------------
			if FI_Movable(group.id) then
				if down then
					_G[f_name]:StartMoving();
				else
					_G[f_name]:StopMovingOrSizing();
				end
			end
		end	
	
	elseif (click == "RightButton") then
		if IsShiftKeyDown() then
			------------------------------------------------------------
			-- SHOW COMMAND REFERENCE
			------------------------------------------------------------
			if (down == false) then
				InterfaceOptionsFrame_OpenToCategory(FI_CONFIG.Pages[5]);
				InterfaceOptionsFrame_OpenToCategory(FI_CONFIG.Pages[5]);
			end
		else
			------------------------------------------------------------
			-- SHOW USER GUIDE
			------------------------------------------------------------
			if (down == false) then
				InterfaceOptionsFrame_OpenToCategory(FI_CONFIG.Pages[4]);
				InterfaceOptionsFrame_OpenToCategory(FI_CONFIG.Pages[4]);
			end
		end
	end
end

-- This function is more of a beast than I prefer, but it gets stuff done.
function FI_Group( action, arg1, arg2 )
	--------------------------------------------------
	-- LIST
	--------------------------------------------------
	if (action == "list") then
		local msg = "Available bar ID's:";
		for index,group in ipairs(FI_SVPC_DATA.Groups) do
			local m;
			if (index < #FI_SVPC_DATA.Groups) then
				m = "  "..index..",";
			else
				m = "  "..index
			end
			
			msg = msg..m;
		end
		FI_Message(msg);
	
	--------------------------------------------------
	-- ADD
	--------------------------------------------------
	elseif (action == "add") then
		local key = #FI_SVPC_DATA.Groups +1;
		
		if (key > FI_DEFAULTS.MaxGroups) then
			FI_Message("The maximum number of bars allowed is "..FI_DEFAULTS.MaxGroups..".");
		else
			-- insert group record
			local gid = FI_DB.insert(FI_SVPC_DATA.Groups, FI_DEFAULTS.DB.Group);

			-- populate the group
			for i=1,FI_DEFAULTS.NumButtons do
				-- copy default button data
				local bid = FI_DB.insert(FI_SVPC_DATA.Buttons, FI_DEFAULTS.DB.Button);
				-- assign button to group
				FI_DB.update(FI_SVPC_DATA.Buttons, {id = bid}, {group = gid});
			end
			
			-- create the frames!
			FI_FRAMES.Group(gid);
			FI_Group_Style(gid);
		end

	--------------------------------------------------
	-- REMOVE
	-- arg1 == index (bar number)
	--------------------------------------------------
	elseif (action == "remove") then
		-- automated group removal
		if not arg1 then
			arg1 = #FI_SVPC_DATA.Groups;
		end
		
		-- map bar number to group data
		local group = FI_SVPC_DATA.Groups[arg1]
		
		if group then
			-- remove associated buttons (empty the group)
			for i,bid in ipairs(FI_Group_Members(group.id)) do
				FI_DB.delete(FI_SVPC_DATA.Buttons, {id = bid});
			end
			
			-- delete group record
			FI_DB.delete(FI_SVPC_DATA.Groups, {id = group.id});
			
			-- commit the changes
			if (FI_LOADING == false) then
				ReloadUI();
			end
		else
			FI_Message("Invalid bar number.");
		end
		
	--------------------------------------------------
	-- SIZE (NUMBER OF BUTTONS IN THE GROUP)
	--   This regulates the number of actual button records in the database. To simply show/hide buttons, see FI_QuickSize()
	-- arg1 == gid
	-- arg2 == FI_SVPC_DATA.Groups.i.size
	--------------------------------------------------
	elseif (action == "size") then
		-- map bar number to group data
		local group = FI_SVPC_DATA.Groups[arg1]
		local buttons = FI_Group_Members(group.id);
		local newsize = arg2;
		
		if group then
			-- bar must have at least one button in the group. to hide all buttons use "/farmit show {bar#}" or see FI_QuickSize()
			if (newsize < 1) or (newsize > FI_DEFAULTS.MaxButtons) then
				FI_Message("Bar size must be a whole number between 1 and "..FI_DEFAULTS.MaxButtons..".");
			else
				-- are we adding or subtracting?
				if (newsize > #buttons) then
					--------------------------------------------------
					--  INCREASE
					--------------------------------------------------
					local diff = newsize - #buttons;
					
					for i=1,diff do
						-- insert new button data
						local bid = FI_DB.insert(FI_SVPC_DATA.Buttons, FI_DEFAULTS.DB.Button);
						-- assign button to group
						FI_DB.update(FI_SVPC_DATA.Buttons, {id = bid}, {group = group.id});
					end
					
					-- create the frames
					FI_FRAMES.Button(group.id);

					-- set button visibility to match change in group size
					group = FI_DB.update(FI_SVPC_DATA.Groups, {id = group.id}, {size = #FI_Group_Members(group.id)});
					-- apply visibility setting
					FI_UI_Button(group.id);
				else
					--------------------------------------------------
					--  DECREASE
					--------------------------------------------------
					-- we can't actually destroy frames, and we don't want to reload unless we really have to...
					-- so for now we will hide the button frames and remove their data records, so next time the interface loads they will be gone for good
					for i,bid in ipairs(buttons) do
						if (i > newsize) then
							-- drop the db record
							FI_DB.delete(FI_SVPC_DATA.Buttons, {id = bid});
							
							-- hide the frame
							_G["FI_Button_"..bid]:Hide();
						end
					end
				end
			end
		else
			FI_Message("Invalid bar number.");
		end

	--------------------------------------------------
	-- GROW (BAR ORIENTATION)
	-- arg1 == group.id
	-- arg2 == group.grow
	--------------------------------------------------
	elseif (action == "grow") then
		-- map bar number to group data
		local group = FI_DB.select(FI_SVPC_DATA.Groups, {id = arg1}, true);
		local input = string.upper(arg2);
		local parent = "FI_Group_"..group.id;

		-- validate input
		local options = {"U","D","L","R"};
		local vertical = {"U","D"};
		
		if (input == group.grow) then
			-- skip redundant calls
			return;
			
		elseif tContains(options, input) then
			-- store the new setting
			group = FI_DB.update(FI_SVPC_DATA.Groups, {id = group.id}, {grow = input});
			
			-- bar anchor
			local a = FI_SVPC_STYLE.anchor;
			local b = FI_SVPC_STYLE.button;
			local size_x,size_y,bg_size_x,bg_size_y;
			
			if tContains(vertical,input) then
				-- vertical
				size_x,size_y = a.size[1],a.size[2];
				bg_size_x,bg_size_y = a.background.size[1],a.background.size[2];
			else
				-- horizontal
				size_x,size_y = a.size[2],a.size[1];
				bg_size_x,bg_size_y = a.background.size[2],a.background.size[1];
			end
			
			-- mighty morphin' group anchors! lawl
			_G[parent]:SetSize(size_x, size_y);
			_G[parent.."_Background"]:SetSize(bg_size_x, bg_size_y);

			-- button frames
			local last_frame = parent;
			for i,bid in ipairs(FI_Group_Members(group.id)) do
				local f_name = "FI_Button_"..bid;
				
				-- no padding for first button so it sits against the anchor
				if (last_frame == parent) then pad = a.pad; else pad = b.pad; end
				
				-- determine orientation
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
				
				-- get ready to mooooove
				_G[f_name]:ClearAllPoints();
				
				-- set new frame position
				_G[f_name]:SetPoint(a1, last_frame, a2, x, y);
				
				-- on to the next...
				last_frame = f_name;
				
				-- use group padding value now that the first button is out of the way...
				if (pad == 0) then
					pad = group.pad;
				end
			end
		else
			FI_Message("Valid options for 'grow' are:  U,D,L,R");
		end
		
	end
	return;
end

-- change number of visible buttons without altering button data
function FI_QuickSize( parent, action )
	local query = {
		id = FI_FrameToID( parent:GetName() ),
	}
	local group = FI_DB.select(FI_SVPC_DATA.Groups, query, true);
	local members = FI_Group_Members(group.id);
	
	-- calculate new size
	local newsize = false;
	if (action == "less") then
		if FI_SV_CONFIG.debug then print("Group "..group.id.." MINUS button clicked..."); end

		newsize = group.size -1;

		if (newsize < 0) then
			newsize = nil;
			if FI_SV_CONFIG.debug then print("Minimum bar size reached."); end
		end

	elseif (action == "more") then
		if FI_SV_CONFIG.debug then print("Group "..group.id.." PLUS button clicked..."); end

		newsize = group.size +1;

		if (newsize > #members) then
			newsize = false;
			if FI_SV_CONFIG.debug then print("All the buttons in that group are already showing."); end
		end
	end

	if newsize then
		-- update the group record
		group = FI_DB.update(FI_SVPC_DATA.Groups, {id = group.id}, {size = newsize});
		-- apply the change
		FI_UI_Button(group.id);
	end
end

-- wrapper
function FI_UI()
	-- apply individual group settings
	for i,group in ipairs(FI_SVPC_DATA.Groups) do
		FI_UI_Button(group.id);
	end	
end

-- applies group.size to bar
function FI_UI_Button( gid )
	local group = FI_DB.select(FI_SVPC_DATA.Groups, {id = gid}, true);
	local bids = FI_Group_Members(group.id);
	
	for i,bid in ipairs(bids) do
		if (i > group.size) then
			_G["FI_Button_"..bid]:Hide();
		else
			_G["FI_Button_"..bid]:Show();
		end
	end
end

-- gid (num): if present, toggle visibility of that group only. (otherwise toggle entire addon)
-- setting (bool): use this value
function FI_Show( gid, setting )
	if gid then
		local group = FI_DB.select(FI_SVPC_DATA.Groups, {id = gid}, true);
		
		if (setting == nil) then
			-- toggle group visibility setting
			group = FI_DB.update(FI_SVPC_DATA.Groups, {id = gid}, {show = LIB.toggle(group.show)});
		else
			-- use specified setting
			group = FI_DB.update(FI_SVPC_DATA.Groups, {id = gid}, {show = setting});
		end

		-- apply the change
		if group.show then
			_G["FI_Group_"..group.id]:Show();
		else
			_G["FI_Group_"..group.id]:Hide();
		end
	else
		if (setting == nil) then
			-- toggle global visibility setting
			FI_SVPC_CONFIG.show = LIB.toggle(FI_SVPC_CONFIG.show);
		else
			-- use specified global visibility setting
			FI_SVPC_CONFIG.show = setting;
		end
		
		-- apply the change
		if FI_SVPC_CONFIG.show then
			_G["FI_PARENT"]:Show();
		else
			_G["FI_PARENT"]:Hide();
		end
	end
end

function FI_Alpha( alpha, gid )
	if gid then
		-- set group alpha for a specific bar
		FI_DB.update(FI_SVPC_DATA.Groups, {id = gid}, {alpha = tonumber(alpha)});
		_G["FI_Group_"..gid]:SetAlpha(alpha);

	elseif alpha then
		-- set parent alpha of entire addon
		FI_SVPC_CONFIG.alpha = tonumber(alpha);
		_G["FI_PARENT"]:SetAlpha(FI_SVPC_CONFIG.alpha);
	end
end

-- scale : (numeric) decimal value for visual scaling of frames. (1.25 = 125%)
-- gid   : (numeric) if present, apply setting to this group only.
function FI_Scale( newscale, gid )
	if gid and newscale then
		-- change group setting
		FI_DB.update(FI_SVPC_DATA.Groups, {id = gid}, {scale = newscale});
		-- apply the change
		_G["FI_Group_"..gid]:SetScale(newscale);
	elseif newscale then
		-- change global setting
		FI_SVPC_CONFIG.scale = newscale;
		-- apply the change
		_G["FI_PARENT"]:SetScale(newscale);
	else
		-- apply individual group settings
		for i,group in ipairs(FI_SVPC_DATA.Groups) do
			_G["FI_Group_"..group.id]:SetScale(group.scale);
		end
		-- apply global scale saved setting
		_G["FI_PARENT"]:SetScale(FI_SVPC_CONFIG.scale);
	end
end

--------------------------------------------------------------------------------
--  TEMPLATES
--------------------------------------------------------------------------------

function FI_Template( action, arg, val, val2 )
	local actions = {"save","load","delete","list","rename"};
	
	if tContains(actions, action) then
		if (action == "save") then
			FI_TPL.save(arg, val);
		
		elseif (action == "load") then
			FI_TPL.load(arg, val, val2);
		
		elseif (action == "delete") then
			FI_TPL.delete(arg);
		
		elseif (action == "list") then
			FI_TPL.list(arg, val);
		
		elseif (action == "rename") then
			FI_TPL.rename(arg, val);
		end
	else
		FI_Message("Valid template actions are:  "..table.concat(actions,", "));
	end
end

FI_TPL.save = function( bar, name )
	if bar then
		bar = tonumber(bar);
		local group = FI_SVPC_DATA.Groups[bar];
		
		if group then
			-- check template name
			if name then
				-- validate input
				if (strlen(name) > 2) then
					-- build list of all items on the bar
					local buttons = FI_DB.select(FI_SVPC_DATA.Buttons, {group = group.id});
					
					local items = {};
					for i,button in ipairs(buttons) do
						if button.item then
							table.insert(items, button.item);
						end
					end
					
					----->>  CREATE TEMPLATE  <<-----
					FI_SV_DATA.Templates[name] = LIB.table.copy(items);
					
					FI_Message("All items on bar "..bar.." saved as farming template:  "..name);
				else
					-- error message
					FI_Message("Template names must be at least 3 characters, and have no spaces.");
				end
			else
				-- error message
				FI_Message("Please provide a template name when saving an item bar:  /farmit tpl save 1 MyTemplate");
			end 
		else
			-- error message
			FI_Message("Invalid bar number.");
		end
	else
		-- error message
		FI_Message("Please specify the bar number you wish to save. Also, be sure to include a template name:  /farmit tpl save 1 MyTemplate");
	end
end

FI_TPL.load = function( bar, val, val2 )
	if FI_SV_CONFIG.debug then
		local params = "";
		if val2 then
			params = bar..", "..val..", "..val2;
		elseif val then
			params = bar..", "..val;
		elseif bar then
			params = bar;
		end
		print("[FI_TPL.load]  Parameters:  "..params);
	end
	
	if bar then
		bar = tonumber(bar);
		local group = FI_SVPC_DATA.Groups[bar];
		
		if group then
			-- check input
			if val then
				local category,name,items;

				-- parse input (fixed in v2.22)
				if val2 then
					-- built-in templates
					category = strupper(tostring(val));
					name = tostring(val2);
					
					items = FI_TPL.Templates[category][name]
				else
					-- user created template
					category = "USER";
					name = val;
					
					items = FI_SV_DATA.Templates[name]
				end
				
				----->>  check template path  <<-----
				if items then
					local bids = FI_Group_Members(group.id);
					
					----->>  check bar size  <<-----
					if (#items > #bids) then
						FI_Group("size", group.id, #items);
					end
					
					FI_LOADING = true;
					----->>  clear the bar  <<-----
					for i,bid in ipairs(bids) do
						FI_Clear_Button(bid);
					end
					
					----->>  apply template to bar  <<-----
					for i,itemID in ipairs(items) do
						FI_Set_Button(bids[i], itemID);
					end
					FI_LOADING = false;
					
					-- check visibility
					if (#items > group.size) then --remove this condition?
						group = FI_DB.update(FI_SVPC_DATA.Groups, {id = group.id}, {size = #items});
						FI_UI_Button(group.id);
					end

					-- done!
					FI_Message("Template '"..category.."\\"..name.."' loaded on bar "..bar..".");
				else
					-- error message
					FI_Message("Error finding template:  "..category.."\\"..name.."\n  To see a list of valid options, type:  /farmit tpl list");
				end
			else
				-- error message
				FI_Message("Please specify a template to load.");
			end 
		else
			-- error message
			FI_Message("Invalid bar number.");
		end
	else
		-- error message
		FI_Message("Please specify the bar number you wish to load a template on.");
	end
end

FI_TPL.delete = function( name )
	if name then
		local name = tostring(name);
		
		-- check path
		if FI_SV_DATA.Templates[name] then
			-- bye bye!
			FI_SV_DATA.Templates[name] = nil;
			FI_Message("User template '"..name.."' deleted.");
		else
			FI_Message("Error finding user template:  "..name.."\n  To see a list of valid options, type:  /farmit tpl list");
		end
	else
		-- error message
		FI_Message("Please specify the name of the template you wish to delete. To see a list of valid options, type:  /farmit tpl list");
	end
end

FI_TPL.list = function( arg )
	local options = LIB.table.keys(FI_SV_DATA.Templates);
	local output;
	
	-- build user list
	local user_list = {};
	user_list[1] = "User created templates:";
	user_list[2] = "    "..table.concat(LIB.table.keys(FI_SV_DATA.Templates, true), ", ");
	
	if arg then
		-- category list
		local cat = strupper(arg);
		
		if tContains(options, cat) then
			-- build a selective list (one category)
			local category = {};
			category[1] = "Built-in '"..cat.."' templates:";
			category[2] = "    "..table.concat(LIB.table.keys(FI_TPL.Templates[cat], true), ", ");
			
			output = category;
		
		elseif (arg == "USER") then
			output = user_list;
		
		else
			-- error message
			output = "Template category '"..cat.."' not found, valid options are:  "..table.concat(options, ", ");
		end
	
	else
		-- combined list
		local categories = {};
		categories[1] = "Built-in templates:";
		
		for i,cat in ipairs(FI_TPL.Order) do
			local heading = "    "..cat..":  ";
			local contents = table.concat(LIB.table.keys(FI_TPL.Templates[cat], true), ", ");
			table.insert(categories, heading..contents);
		end
		
		table.insert(categories, user_list[1]);
		table.insert(categories, user_list[2]);
		
		output = categories;
	end
	
	FI_Message(output);
end

FI_TPL.rename = function( arg, val )
	local output;
	
	if arg and val then
		local old = tostring(arg);
		local new = tostring(val);
		
		if FI_SV_DATA.Templates[old] then
			if (strlen(new) > 2) then
				FI_SV_DATA.Templates[new] = LIB.table.copy(FI_SV_DATA.Templates[old]);
				FI_SV_DATA.Templates[old] = nil;
				output = "User template '"..old.."' renamed to: "..new;
			else
				output = "New template name must be at least 3 characters long, and have no spaces.";
			end
		else
			output = "Template '"..old.."' not found. For a list of valid options, type:  /farmit tpl list user";
		end
	else
		output = "To rename a template, please specify the old name and include a new name:  /farmit tpl rename oldname newname";
	end
	
	FI_Message(output);
end
