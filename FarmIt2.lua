--------------------------------------------------------------------------------
--  FarmIt
--
--  TO DO:
--[[

A   Write a centralized DebugOut() function.

A	Fix the confusing discrepancy that "group.move = true" means the bar is movable, and "FI_Lock(true)" implies the bar is locked.

A	GUI config panel!

A	Make item data (counts) from your other characters accessible.
	* Move button data into FI_SV_DATA.
	* Store BOTH local and bank-included item queries every time button is updated.
	* Holding a modifier key (alt?) will add item counts from other toons to item-button tooltips.

B	Basic money tracking during a "session" (money looted).
B	Data visualization for session tracking.

C	Calculate estimated drop rates for tracked items. (estimated rate of acquisition)

D	Templates enhancement: Store the required profession skill level along with items, then display it in the tooltip.
	Then check the current skill level of the player in their profession related to the item, 
	and highlight the item with an unobtrusive red outline if their skill level is too low to gather it.

D	Profiles.

E	Work with auctioneer/auctionator to calculate the AH value of tracked items.
E	Support for ButtonFacade
E	Support for Skinner

]]--

--------------------------------------------------------------------------------
--  EVENT REGISTRATION
--------------------------------------------------------------------------------
function FI_OnLoad(self)
	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("BAG_UPDATE");
	self:RegisterEvent("PLAYER_REGEN_ENABLED");
	--self:RegisterEvent("BAG_UPDATE_COOLDOWN");

	self:RegisterEvent("CHAT_MSG_MONEY");
	self:RegisterEvent("CHAT_MSG_CURRENCY");
	self:RegisterEvent("CHAT_MSG_COMBAT_HONOR_GAIN");
	self:RegisterEvent("CURRENCY_DISPLAY_UPDATE");
	
	SlashCmdList["farmit"] = FI_Command;
	SLASH_farmit1 = "/farmit";
	
	StaticPopupDialogs["RELOAD"] = {
		text = "This action will reload your game interface. Are you sure?",
		button1 = "RELOAD",
		button2 = "Cancel",
		OnAccept = function()
			ReloadUI();
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["STYLE"] = {
		text = "Changing FarmIt's graphical theme requires reloading your game interface. Are you sure?",
		button1 = "OK",
		button2 = "Cancel",
		OnAccept = function()
			-- replace function before popup call!
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	
	StaticPopupDialogs["RESET"] = {
		text = "This will reset FarmIt to default settings, and reload your game interface. Are you sure?",
		button1 = "RESET",
		button2 = "Cancel",
		OnAccept = function()
			FI_Reset();
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		showAlert = true,
	}
	
	StaticPopupDialogs["DELETE"] = {
		text = "NOTE: Removing a bar destroys it completely and requires an interface reload. "..
			"If you don't want to do that right now, try hiding the bar with the command:  /farmit show %s",
		button1 = "DELETE",
		button2 = "Cancel",
		OnAccept = function()
			-- replace function before popup call!
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
end

--------------------------------------------------------------------------------
--  EVENT HANDLER
--------------------------------------------------------------------------------
function FI_OnEvent(self, event, ...)
	local arg = ...;
	
	-- debug
	local filter = "BAG_UPDATE";
	if FI_SV_CONFIG and FI_SV_CONFIG.debug and (event ~= filter) and arg then
		if (type(arg) == "table") then 
			print("OnEvent() fired: "..event); --debug
		else
			print("OnEvent() fired: "..event.." "..arg); --debug
		end
	end
	
	-- event dispatch
	if (event == "ADDON_LOADED") and (arg == "FarmIt2") then
		FI_ADDON_LOADED = true;
		
		self:UnregisterEvent("ADDON_LOADED");
		
		FI_LOADING = true;
			FI_Init();
			FI_Render();
			FI_Load();
		FI_LOADING = false;
	
	elseif (FI_ADDON_LOADED == true) then
		if (event == "BAG_UPDATE") and (FI_ADDON_LOADED == true) then
			FI_Update(arg);
		
		elseif (event == "CURRENCY_DISPLAY_UPDATE") or (event == "CHAT_MSG_CURRENCY") or (event == "CHAT_MSG_COMBAT_HONOR_GAIN") then
			FI_Update_Currency(event);
		
		elseif (event == "CHAT_MSG_MONEY") then
			FI_Update_Money(event, arg);
		
		elseif (event == "PLAYER_REGEN_ENABLED") then
			-- fix for item-button secure header interfering with quicksize while in combat
			FI_UI();
		end
	end
end


--------------------------------------------------------------------------------
--  COMMAND DISPATCHER
--------------------------------------------------------------------------------
function FI_Command( input, editbox )
	--------------------------------------------------
	--  PARSE INPUT
	--------------------------------------------------
	local cmd, arg, val, val2, val3 = strsplit(' ', input);

	--------------------------------------------------
	--  COMMANDS
	--------------------------------------------------
	cmd = strlower(cmd);
	
	if (cmd == "help") then
		InterfaceOptionsFrame_OpenToCategory(FI_CONFIG.Pages[4]);
		InterfaceOptionsFrame_OpenToCategory(FI_CONFIG.Pages[4]);
	
	elseif (cmd == "options") or (cmd == "config") then
		InterfaceOptionsFrame_OpenToCategory(FI_CONFIG.Pages[5]);
		InterfaceOptionsFrame_OpenToCategory(FI_CONFIG.Pages[5]);
	
	elseif (cmd == "reset") then
		StaticPopup_Show("RESET");
	
	elseif (cmd == "rebuild") then --for ninjas pwnly!!!
		if arg then
			FI_DB.rebuild( strlower(arg) );
		else
			FI_DB.rebuild("all");
		end
		ReloadUI();
	
	elseif (cmd == "debug") then
		FI_SV_CONFIG.debug = LIB.toggle(FI_SV_CONFIG.debug);
		FI_Message("Debugging output:  "..strupper(tostring(FI_SV_CONFIG.debug)));
	
	elseif (cmd == "show") or (cmd == "toggle") then
		if arg then
			local bar = tonumber(arg);
			if FI_SVPC_DATA.Groups[bar] then
				FI_Show( FI_SVPC_DATA.Groups[bar]["id"] );
			else
				FI_Message("Invalid bar number.");
			end
		else
			FI_Show();
		end
	
	elseif (cmd == "lock") then
		if arg then
			local bar = tonumber(arg);
			if FI_SVPC_DATA.Groups[bar] then
				FI_Lock(bar);
			else
				FI_Message("Invalid bar number.");
			end
		else
			FI_GlobalLock(false);
		end
	
	elseif (cmd == "unlock") then
		if arg then
			local bar = tonumber(arg);
			if FI_SVPC_DATA.Groups[bar] then
				FI_Unlock(bar);
			else
				FI_Message("Invalid bar number.");
			end
		else
			FI_GlobalLock(true);
		end
	
	elseif (cmd == "tooltip") then
		local opt_msg = "Valid options are:  bar, button, currency \nFor example:  /farmit tooltip bar";
		if arg then
			local tip = string.lower(tostring(arg));
			if (FI_SV_CONFIG.Tooltips[tip] == nil) then
				FI_Message("Unrecognised tooltip type. "..opt_msg);
			else
				FI_SV_CONFIG.Tooltips[tip] = LIB.toggle(FI_SV_CONFIG.Tooltips[tip]);
				FI_Message( tip.." tooltips are now "..LIB.BoolToString(FI_SV_CONFIG.Tooltips[tip],3) );
			end
		else
			FI_Message(opt_msg);
		end
	
	elseif (cmd == "scale") then
		if arg then
			local scale = tonumber(arg);
			if val then
				--prevent misplaced values from causing trouble
				local bar = LIB.round(tonumber(val));
				if (bar >= 1) and (bar <= #FI_SVPC_DATA.Groups) then
					FI_Scale(scale, FI_SVPC_DATA.Groups[bar]["id"]);
				else
					FI_Message("Bar number '"..val.."' not found.");
				end
			else
				FI_Scale(scale);
			end
		end
	
	elseif (cmd == "alpha") then
		if arg then
			if val then
				local bar = tonumber(val);
				FI_Alpha( tonumber(arg), FI_SVPC_DATA.Groups[bar]["id"] );
			else
				FI_Alpha( tonumber(arg) );
			end
		end
	
	elseif (cmd == "alerts") then
		if arg then
			FI_Toggle_Alert( strlower(arg) );
		else
			FI_Alert_Info();
		end
	
	elseif (cmd == "currency") then
		if arg then
			FI_Toggle_Currency( strlower(arg), val );
		else
			FI_Toggle_Currency();
		end
	
	elseif (cmd == "group") then
		if arg then
			local action = strlower(arg);
			
			if (action == "add") then
				FI_Group(action);
			
			elseif (action == "remove") then
				local bar;
				
				if val then
					-- remove specified bar
					bar = tonumber(val);
				else
					-- automatically remove the last bar that was added
					bar = #FI_SVPC_DATA.Groups;
				end
				
				-- set popup callback
				StaticPopupDialogs["DELETE"].OnAccept = function() FI_Group("remove", FI_SVPC_DATA.Groups[bar]["id"] ); end
				-- show dialog
				StaticPopup_Show("DELETE", bar);
			
			elseif (action == "list") then
				FI_Group(action);
			end
		end
	
	elseif (cmd == "size") then
		if arg then
			local bar = tonumber(arg);
			if val then
				FI_Group("size", FI_SVPC_DATA.Groups[bar]["id"], tonumber(val) );
			else
				FI_Message("Please specify the number of buttons you want the bar to have.");
			end
		end
	
	elseif (cmd == "grow") then
		if arg then
			if val then
				local gid = FI_SVPC_DATA.Groups[tonumber(arg)]["id"];
				FI_Group("grow", gid, tostring(val));
			else
				FI_Message("Please choose a direction for the bar to grow:  U,D,L,R");
			end
		end
	
	elseif (cmd == "style") then
		if arg then
			-- set popup callback
			StaticPopupDialogs["STYLE"].OnAccept = function() FI_Style( strlower(arg) ); end
			StaticPopup_Show("STYLE");
		end
	
	elseif (cmd == "tpl") then
		if arg then
			FI_Template( strlower(arg), val, val2, val3 );
		end
		
	elseif (cmd == "session") then
		if arg then
			local act = strlower(arg);
			local session;
			
			if (act == "start") then
				session = FI_SESSION.start();
				FI_Message("Farming session started: SID "..session.id..", "..date("%c", session.start) );
			elseif (act == "stop") then
				session = FI_SESSION.stop();
				FI_Message("Farming session stopped: SID "..session.id..", "..date("%c", session.stop) );
			elseif (act == "reset") then
				FI_SESSION.reset();
				FI_Message("Session data cleared.");
			else
				FI_Message("Valid options for '/farmit session' are:  start, stop, reset");
			end
		else
			-- display a "current session info" message
			FI_SESSION.info();
		end
	
	-- undocumented command (for testing automation) added in v2.17
	elseif (cmd == "button") then
		if arg then
			local bid = tonumber(arg);
			if val then
				local setting = strlower(val);
				if (setting == "bank") then
					FI_Toggle_Bank(bid);
				elseif (setting == "objective") then
					if val2 then
						local input = tonumber(val2);
						FI_Set_Objective("Buttons", bid, input);
					else
						FI_Message("Please include a number to set the objective to.");
					end
				end
			else
				FI_Message("Please specify a button setting to change. Valid options are:  bank, objective");
			end
		else
			FI_Message("Please specify a Button ID. Mouse over any occupied button to see its ID.");
		end
	
	else
		-- no valid options given, show help prompt
		FI_Message("Basic commands:\n"..
			"show\n"..
			"        Toggle display of all FarmIt bars at once.\n"..
			"        Controls individual bars if followed by a bar number.\n"..
			"help\n"..
			"        Opens the help page.\n"..
			"options\n"..
			"        Shows a full list of configuration commands."
		);
		
	end
end
