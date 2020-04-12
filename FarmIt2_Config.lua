--------------------------------------------------------------------------------
--  GUI Configuration Panel
--
--  To open directly:
--    InterfaceOptionsFrame_OpenToCategory(panel);
--  or
--    InterfaceOptionsFrame_OpenToCategory(panel.name);
--  
--------------------------------------------------------------------------------

local yellow,green,blue,white = "|cFFFFFF00","|cFF00FF00","|cFF00CCFF","|cFFFFFFFF";

--------------------------------------------------------------------------------
--  CONFIG PANELS
--------------------------------------------------------------------------------
FI_CONFIG.Panel = CreateFrame("Frame", "FI_Panel", UIParent);
FI_CONFIG.Panel.name = "FarmIt";
InterfaceOptions_AddCategory(FI_CONFIG.Panel);

FI_CONFIG.Pages = {
	CreateFrame("Frame", "FI_Panel_1", FI_CONFIG.Panel),
	CreateFrame("Frame", "FI_Panel_2", FI_CONFIG.Panel),
	CreateFrame("Frame", "FI_Panel_3", FI_CONFIG.Panel),
	CreateFrame("Frame", "FI_Panel_4", FI_CONFIG.Panel),
	CreateFrame("Frame", "FI_Panel_5", FI_CONFIG.Panel),
};

FI_CONFIG.Pages[1]["name"] = "General";
FI_CONFIG.Pages[1]["parent"] = FI_CONFIG.Panel.name;
--InterfaceOptions_AddCategory(FI_Panel_1);

FI_CONFIG.Pages[2]["name"] = "Buttons";
FI_CONFIG.Pages[2]["parent"] = FI_CONFIG.Panel.name;
--InterfaceOptions_AddCategory(FI_Panel_2);

FI_CONFIG.Pages[3]["name"] = "Bars";
FI_CONFIG.Pages[3]["parent"] = FI_CONFIG.Panel.name;
--InterfaceOptions_AddCategory(FI_Panel_3);

FI_CONFIG.Pages[4]["name"] = "Help";
FI_CONFIG.Pages[4]["parent"] = FI_CONFIG.Panel.name;
InterfaceOptions_AddCategory(FI_Panel_4);

FI_CONFIG.Pages[5]["name"] = "Commands";
FI_CONFIG.Pages[5]["parent"] = FI_CONFIG.Panel.name;
InterfaceOptions_AddCategory(FI_Panel_5);


--------------------------------------------------------------------------------
--  CONFIGURATION FUNCTIONS
--------------------------------------------------------------------------------
function FI_CONFIG.Load( self )
end

function FI_CONFIG.Show( self )
end

function FI_CONFIG.Get()
end

function FI_CONFIG.Set()
end

function FI_Alert_Info()
	local output = {};
	output[1] = "Alerts settings:";
	
	table.sort(FI_SV_CONFIG.Alerts);
	for key,val in pairs(FI_SV_CONFIG.Alerts) do
		local setting;
		if val then setting = "ON"; else setting = "OFF"; end
		
		table.insert(output, "  "..key.." = "..setting);
	end
	
	FI_Message(output);
end

function FI_Toggle_Alert( arg )
	local options = {};
	for key,val in pairs(FI_DEFAULTS.SV.CONFIG.Alerts) do
		table.insert(options, key);
	end
	
	local msg;
	if tContains(options, arg) then
		local result;
		
		FI_SV_CONFIG.Alerts[arg] = LIB.toggle( FI_SV_CONFIG.Alerts[arg] );
		if FI_SV_CONFIG.Alerts[arg] then result = "ON"; else result = "OFF"; end
		
		-- customized response messages
		if (arg == "chat") then
			msg = "Chat window alerts:  "..result;
		elseif (arg == "screen") then
			msg = "On-screen alerts:  "..result;
		elseif (arg == "sound") then
			msg = "Alert sounds:  "..result;
		else
			msg = "Input error!";
		end
		
	else
		msg = "Invalid input. Options for 'alert' are:  "..table.concat(options,", ");
	end
	
	-- response
	FI_Message(msg);
end

function FI_Toggle_Currency( setting, input, silent )
	local options = LIB.table.keys(FI_SVPC_CONFIG.Currency);
	local msg;
	
	if setting then
		-- validate input
		if (FI_SVPC_CONFIG.Currency[setting] ~= nil) then
			-- config check
			if (FI_SVPC_CONFIG.Currency.tracking == true) then
				-- process input
				local value;
				
				if (type(FI_SVPC_CONFIG.Currency[setting]) == "boolean") then
					-- change boolean setting
					FI_SVPC_CONFIG.Currency[setting] = LIB.toggle(FI_SVPC_CONFIG.Currency[setting]);
					value = strupper(tostring(FI_SVPC_CONFIG.Currency[setting]));
				
				elseif input and (type(FI_SVPC_CONFIG.Currency[setting]) == "number") then
					-- change numeric setting
					FI_SVPC_CONFIG.Currency[setting] = LIB.round(tonumber(input),2);
					value = FI_SVPC_CONFIG.Currency[setting];
				
				elseif input then
					-- change string setting
					FI_SVPC_CONFIG.Currency[setting] = tostring(input);
					value = FI_SVPC_CONFIG.Currency[setting];
				else
					-- input error
				end
				
				-- output
				msg = "Currency bar:  "..setting.." = "..value;
			
			else
				msg = "Currency tracking is currently disabled. To enable it, type:  /farmit currency";
			end
		else
			msg = "Invalid input. Options for 'currency' are:  "..table.concat(options,", ");
		end
	
	else
		-- toggle main setting
		FI_SVPC_CONFIG.Currency.tracking = LIB.toggle(FI_SVPC_CONFIG.Currency.tracking);
		
		if (FI_SVPC_CONFIG.Currency.tracking == true) then
			FI_SVPC_CONFIG.Currency.show = true;
		else
			FI_SVPC_CONFIG.Currency.show = false;
		end
		
		msg = {};
		msg[1] = "Currency tracking = "..strupper(tostring(FI_SVPC_CONFIG.Currency.tracking));
		msg[2] = "Currency bar:  show = "..strupper(tostring(FI_SVPC_CONFIG.Currency.show));
	end
	
	-- update interface
	FI_Update_Currency();
	
	-- output
	if (not silent) then
		FI_Message(msg);
	end
	
	-- return current state
	return FI_SVPC_CONFIG.Currency;
end

--------------------------------------------------------------------------------
--  HELP TEXT
--------------------------------------------------------------------------------
FI_HELP_TEXT = [[The latest version of this guide can be found online at: 
http://wow.curseforge.com/addons/farm-it/pages/user-guide/

Click the "Commands" page on the left to see a full list of configurations commands.

--------------------------------------------------------------------------------

FarmIt offers "set it and forget it" farming objectives. 

Current item count is displayed in the bottom-right corner of each slot, and your goal amount in the top-left corner. Optionally, you will be notified each time you loot an item that you are tracking. When you reach your farming objective for a given item, the goal amount turns green and you will receive a "quest completed" notification. You can hide some or all parts of FarmIt and your farming items will still be monitored.

FarmIt is able to include your current bank inventory in real-time, without needing to visit the bank! 

Bar orientation can be switched between vertical and horizontal. The direction the bar "grows" (up, down, left, right) can also be changed, and bar length can be adjusted. Bar visibility can be toggled individually, or all at once.

You can save a set of items from any FarmIt bar as a "farming template" for use again later. FarmIt includes some built-in templates for each of the standard gathering professions.

|cFF00FF00---==( Item Buttons )==---|cFFFFFFFF

Place any item from your inventory into one of FarmIt's bar slots to keep track of how many you have. Click on an occupied slot to select its contents and move them to another slot. If the destination slot has an item in it already, the items will trade places.

Right-click a slot to "use" the item. (For combining scraps into hides, etc.)

Shift-click the slot to have it include your bank inventory, you do *not* need to be at the bank for this to work! When 'include bank' is enabled, a four-point gold border will appear around the item button. The "bank included" state is also visible by mousing over the item slot.

Shift+Right-click a slot to clear it.

Ctrl+Click a slot to set a farming objective for that item. This works similar to WoW quest tracking. FarmIt will notify you each time you progress toward your objective, and upon reaching your goal. The goal number will turn green once it has been reached.

Ctrl+Right-click any bar slot to manually type in a numeric "Item ID". This works great with addons like iTip which add extra information to all item tooltips.

|cFF00FF00---==( Bars )==---|cFFFFFFFF

To move a bar, click and drag the anchor (numbered tab) at the end of the bar. To lock it in place, Shift-click the bar anchor. To lock all bars at once, type: "/farmit lock"

Right-click the bar anchor to open FarmIt's help page.

Shift+Right-click the bar anchor to show a full list of configuration commands.

To grow/shrink the number of *visible* slots on a bar, click the 'quick size' buttons (-/+). To permanently add or remove bar slots, see the "group size" documentation on the "Commands" page.

FarmIt bars can be scaled, made transparent, or hidden completely. See the "Commands" page for more information.

|cFF00FF00---==( Templates )==---|cFFFFFFFF

You can save all the items on a FarmIt bar as a "farming template" to easily track those items again later. Saved farming templates can be loaded onto any FarmIt bar. If there is a difference between the amount of items in the template, and the size of the bar, the bar will automatically adjust to accommodate the template. 

For details on how to save/load your own templates, please refer to the "Commands" page of FarmIt's in-game help.

|cFF00FF00---==( Currency Tracking )==---|cFFFFFFFF

When you use WoW's built-in "Show on Backpack" feature to watch a currency, FarmIt will automatically track the selected currencies and (optionally) display a "Currency HUD" on the screen. You can use this currency bar to set farming objectives and monitor your progress. Use the command "/farmit currency hud" to toggle display of the on-screen currency bar, or just "/farmit currency" to turn currency tracking on/off entirely.

To set a farming goal for a currency, simply right-click the currency amount on FarmIt's currency bar (or at the bottom of your backpack). Once a currency objective has been set, the goal amount will appear in the currency bar tooltips, and the currency tooltips at the bottom of your backpack.

Currency objectives follow the same color scheme as regular item objectives, ie: the objective turns green when the goal has been reached.

To move the currency bar, hold the Shift key and then drag the bar where you want it.

]];

FI_COMMANDS_TEXT = [[|cFFFFFFFF
|cFFFFFF00help|r

  Show the help window.


|cFFFFFF00options||config|r

  Show the configuration window.


|cFFFFFF00reset|r

  Reset the mod to default settings.


|cFFFFFF00show|cFF00FF00 {#}|r

  Toggle visibility of a button group, by bar number. Shows/hides all bars at once if no number given.


|cFFFFFF00lock|cFF00FF00 {#}|r

  Toggle position lock, by bar number. Lock/unlock all bars at once if no bar number given.


|cFFFFFF00scale|cFF00FF00 {%} {#}|r

  Change the visual scale of the addon, in decimal format: 1.25 = 125%. If a bar number is given, only that bar will be scaled.


|cFFFFFF00alpha|cFF00FF00 {#} {#}|r

  Change the opacity of the addon in decimal format, from 0 (invisible) to 1.0 (opaque). If a bar number is given, only that bar will be changed.


|cFFFFFF00alerts|cFF00FF00 {chat||screen||sound}|r

  Toggle alerts ON/OFF by type. For example: '/farmit alerts screen' enables/disables on-screen announcements. If no option is given, the current state of all alert settings will be displayed.


|cFFFFFF00tooltip|cFF00FF00 {bar|button|currency}|r

  Enable/disable display of FarmIt's tooltips, by category. For example, to disable the tooltip on all bar *anchors*, you would type: /farmit tooltip bar


|cFFFFFF00currency|cFF00FF00 {show|scale|alpha}|r

  |cFF00FF00show|r
    Toggle display of the currency bar.

  |cFF00FF00scale|cFF00CCFF {#}|r
    Change the visual scale of the currency bar, in decimal format: 1.25 = 125%.

  |cFF00FF00alpha|cFF00CCFF {#}|r
    Change the opacity of the currency bar, in decimal format, from 0 (invisible) to 1.0 (opaque).

  If no option is present (ie: '/farmit currency'), toggles all currency tracking features ON/OFF at once. (per character)


|cFFFFFF00group|cFF00FF00 {add||remove||list}|r

  |cFF00FF00add|r

  Adds a new bar (there is a limit of 24 bars total). New bars start with 12 buttons (4 of them showing) with a limit of 48 buttons per bar.

  |cFF00FF00remove|cFF00CCFF {#}|r

  Include the bar number of the button group you wish to delete. This permanently destroys the group and all of its buttons! If no bar number is given, the last bar that was created (highest number) will be deleted.

  |cFF00FF00list|r

    Prints a list of all existing bar ID's. Useful if you have hidden individual bars.


|cFFFFFF00size|cFF00FF00 {#} {#}|r

  Set the total number of buttons available on a given bar. There is a limit of 48 slots per bar. For example: '/farmit size 1 10' would configure bar number one to have ten total buttons available on it. Setting a bar to a smaller size will permanently delete any extra buttons. To simply hide some button spaces without destroying them, click on the 'quick size' buttons (-/+).


|cFFFFFF00grow|cFF00FF00 {#} {L||R||U||D}|r

  Controls the direction that a button group grows- (L)eft, (R)ight, (U)p, (D)own. For example: '/farmit grow 1 R' sets bar #1 to horizontal mode, growing to the right.


|cFFFFFF00style|cFF00FF00 {default|minimal}|r

  Choose a visual style (requires UI reload):

    |cFF00FF00default|r

      Meant to match the stock WoW interface.

    |cFF00FF00minimal|r

      Goes better with addons like Bartender.

  If you feel adventurous, you can edit FarmIt2_Style.lua to add your own graphical themes.


|cFFFFFF00tpl|cFF00FF00 {save|load|delete|list}|r

  |cFF00FF00save|cFF00CCFF {#} {name}|r
  
    Saves all the items in a given bar as a farming template for use again later. Specify the bar number you want to save, followed by a template name. Template names are case sensitive, must be at least 3 characters, and have no spaces.

  |cFF00FF00load|cFF00CCFF {#} {category} {name}|r

    Loads a saved item set (template) into the specified bar, by name (case sensitive). The category can be omitted when loading user created templates. 

    For example:  /farmit tpl load MyTemplate

  |cFF00FF00delete|cFF00CCFF {name}|r

    Delete a user created template, by name. 
    To show all user templates, type:  /farmit tpl list

  |cFF00FF00list|cFF00CCFF {category}|r

    Specify a category to list the available bar templates it contains. Categories are: WOW, TBC, WOTLK, CATA. If no category is given, the list will show all the user created templates.


|cFFFFFF00rebuild|r

  Rebuilds ALL data tables and reloads the UI. Only use this if you are having problems with saved data like templates, etc.  WARNING: This will wipe out all your bars, preferences, and saved templates!
]];
