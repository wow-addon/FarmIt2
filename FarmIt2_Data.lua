--------------------------------------------------------------------------------
--  BOOTSTRAP
--
--  Dependency: lualib\trunk\LibGLHF.lua
--
--	SavedVariablesPerCharacter: FI_SVPC_CONFIG,FI_SVPC_STYLE,FI_SVPC_DATA,FI_SVPC_CACHE
--	SavedVariables: FI_SV_CONFIG,FI_SV_DATA
--------------------------------------------------------------------------------

FI_TITLE = "FarmIt2";
FI_VERSION = 2.38;
FI_MIN_VERSION = 2.2; --minimum compatible version
FI_RELEASE = "RELEASE"; --ALPHA|BETA|RELEASE.
FI_TAGLINE = "FarmIt v"..FI_VERSION.." "..FI_RELEASE;
FI_REQUIRES_RESET = false; --won't touch user data
FI_REQUIRES_REBUILD = false; --global reset!
FI_REBUILD_CONFIG = false; --forces a rebuild of all config settings

FI_LOAD_TS = time(); --timestamp
FI_LOAD_STATES = {"initialized","updated","loaded"};
FI_STATUS = 1; --load status
FI_MOVING = false; --alters behavior of some functions
FI_SPAM_LIMIT = 1; --seconds
FI_MIN_UPTIME = 10; --seconds
FI_ALERT_TS = 0; --timestamp

FI_ADDON_LOADED = false;
FI_CURRENCY_LOADED = false;
FI_BAGS_LOADED = false;

-- FarmIt's clipboard
FI_SELECTED = false;


--------------------------------------------------------------------------------
--  DEFAULT VALUES
--------------------------------------------------------------------------------
FI_DEFAULTS = {};
FI_DEFAULTS["NumGroups"] = 1; --default number of bars to start with
FI_DEFAULTS["NumButtons"] = 12; --default number of buttons on a bar

--  Prevent users from accidentally creating potential performance issues
FI_DEFAULTS["MaxGroups"] = 25; --max number of bars
FI_DEFAULTS["MaxButtons"] = 100; --max number of buttons allowed on a bar


--  DB RECORD FORMATS ----------------------------------------------------------
FI_DEFAULTS["DB"] = {
	["Group"] = {
		["id"] = 0,
		["show"] = true,
		["move"] = true,
		["grow"] = "U", -- L(eft), R(ight), U(p), D(own)
		["size"] = 4, -- default number of visible buttons on a bar
		["pad"] = 5,
		["scale"] = 1,
		["alpha"] = 1,
	},
	
	["Button"] = {
		["id"] = 0,
		["group"] = 0, --(foreign key) buttons MUST be assigned to a group after creation!
		["item"] = false,
		["bank"] = false,
		["count"] = 0,
		["lastcount"] = 0,
		["objective"] = 0,
		["success"] = false,
	},
	
	["Currency"] = {
		["id"] = 0,
		["name"] = "",
		["count"] = 0,
		["icon"] = "",
		["lastcount"] = 0,
		["objective"] = 0,
		["success"] = false,
	},
	
	["Session"] = {
		["id"] = 0,
		["start"] = 0,
		["stop"] = 0,
	},
	
	["Money"] = {
		["id"] = 0,
		["timestamp"] = 0,
		["player"] = "",
		["amount"] = 0,
		["count"] = 0,
		["lastcount"] = 0,
		["objective"] = 0,
		["success"] = false,
	},
}

--  SAVED VARIABLES  -----------------------------------------------------------
FI_DEFAULTS["SV"] = {
	["CONFIG"] = {
		-- shared configuration
		["version"] = FI_VERSION,
		["debug"] = false,
		["Alerts"] = {
			["chat"] = true,
			["screen"] = true,
			["sound"] = true,
		},
		["Colors"] = {
			["progress"] = {1,1,1, "FFFFFF"}, --white
			["objective"] = {1,0.8,0, "FFD700"}, --gold
			["success"] = {0,0.9,0, "00EE00"}, --green
			["currency"] = {0.13,0.4,1, "3399FF"}, --blue
			["money"] = {0.8,0.8,0.8, "CCCCCC"}, --silver
		},
		["Tooltips"] = {
			["bar"] = true,
			["button"] = true,
			["currency"] = true,
		},
	},
	
	["DATA"] = {
		-- farming progress log
		["Log"] = {},
		
		-- money log
		["Money"] = {},
		
		-- user created style settings
		["Templates"] = {},
	},
}
--  SAVED VARIABLES PER CHARACTER  ---------------------------------------------
FI_DEFAULTS["SVPC"] = {
	["CONFIG"] = {
		["version"] = FI_VERSION,
		["Currency"] = {
			["tracking"] = true,
			["show"] = true,
			["scale"] = 1,
			["alpha"] = 1,
		},
		-- user preferences
		["show"] = true,
		["move"] = true,
		["scale"] = 1,
		["alpha"] = 1,
		["style"] = "default",
	},

	["DATA"] = {
		-- core data
		["Groups"] = {}, --group records
		["Buttons"] = {}, --button records
		["Currencies"] = {}, --currency records
		["Sessions"] = {}, --session data records
	},
	
	["CACHE"] = {
		["Currencies"] = {}, --cached currency data
	},
}


--------------------------------------------------------------------------------
--  HELPER FUNCTIONS
--------------------------------------------------------------------------------

-- for mapping xml frames to their data record
-- expects a string in the format: FI_Button_1
function FI_FrameToID( f_name )
	local prefix,frame,id = strsplit("_", f_name);
	return tonumber(id);
end


--------------------------------------------------------------------------------
-- CONFIGURATION SETTINGS OBJECT
--------------------------------------------------------------------------------
FI_CONFIG = {}; -- populated by FarmIt2_Config.lua


--------------------------------------------------------------------------------
-- DATA STORAGE METHODS
--------------------------------------------------------------------------------
FI_DB = {};

-- AUTOINC ---------------------------------------------------------------------
-- expects all records in the table to have a numeric "id" field.
-- tab : (table) target table
FI_DB.autoinc = function( tab )
	local nextID = 1;

	if (#tab > 0) then
		local tmp = {};

		-- extract the IDs
		for i,record in ipairs(tab) do
			table.insert(tmp, record.id);
		end

		-- sort ascending
		table.sort(tmp);

		-- determine next value
		nextID = tmp[#tmp]+1;
	end

	return nextID;
end

-- FIND ------------------------------------------------------------------------
-- tab    : (table) target to search
-- where  : (table) expects an associative array of key==value pairs for search criteria
-- single : (boolean) simplifies formatting when expecting one result
-- any    : (boolean) if true allows partial matching (like sql's "OR" syntax)
FI_DB.find = function( tab, where, single, any )
	local results = {};
	
	for i,record in ipairs(tab) do
		local result,fail = false,false;
		
		-- filter results
		for key,val in pairs(where) do
			-- allow wildcard
			if (val == "*") or (record[key] == val) then
				result = true;
			else
				fail = true;
			end
		end
		
		if ((result == true) and (fail == false)) or (any and (match == true)) then
			table.insert(results, i);
		end
	end
	
	-- return *table index* of matching records
	if single then
		-- returns nil if nothing was found
		return results[1];
	else
		return results;
	end
end

-- INSERT ----------------------------------------------------------------------
-- tab  : (table) target table
-- data : (table) "record" to be inserted. primary key will be set automagically
FI_DB.insert = function( tab, data )
	-- avoid reference headaches
	local record = LIB.table.copy(data);

	-- set primary key
	record["id"] = FI_DB.autoinc(tab);

	-- doooo eeeet!
	table.insert(tab, record);
	
	-- return primary key of new record
	return record.id;
end

-- SELECT ----------------------------------------------------------------------
-- tab    : (table) target to search
-- where  : (table) expects an associative table of {key = value} pairs for search criteria
-- single : (boolean) return first record in the set. simplifies formatting when expecting one result
-- any    : (boolean) if true, allows partial matching. works like sql's "OR" syntax
FI_DB.select = function( tab, where, single, any )
	local results = {};

	local keys = FI_DB.find(tab, where, single, any);
	
	if single and (type(keys) == "number") then
		results = LIB.table.copy(tab[keys]);
	elseif (type(keys) == "table") and (#keys > 0) then
		-- copy contents of matching records into result set
		for i,k in ipairs(keys) do
			table.insert(results, LIB.table.copy(tab[k]));
		end
	else
		results = keys;
	end

	-- this could be: a table with multiple records, a single record (still a table), an empty table, or nil (if single and no result)
	return results;
end

-- UPDATE ----------------------------------------------------------------------
-- tab   : (table) target to search
-- where : (table) expects an associative table of {key = value} pairs for search criteria
-- set   : (table) expects a table with data updates in {key = value} pairs
-- any   : (boolean) if true, allows partial matching. works like sql's "OR" syntax
FI_DB.update = function( tab, where, set, any )
	local results = {};
	
	local keys = FI_DB.find(tab, where, nil, any);
	if (#keys > 0) then
		-- go through each record in the result set
		for i,k in ipairs(keys) do
			-- do updates
			for key,val in pairs(set) do
				tab[k][key] = val;
			end
			-- build set of affected records
			table.insert(results, tab[k]);
		end
	end

	-- return updated copies of affected records
	if (#results == 1) then
		return results[1];
	else
		return results;
	end
end

-- DELETE ----------------------------------------------------------------------
-- tab   : (table) target to search
-- where : (table) expects an associative table of {key = value} pairs for search criteria
FI_DB.delete = function( tab, where )
	local numRecords = 0;

	local keys = FI_DB.find(tab, where);
	numRecords = #keys;
	
	if (numRecords > 0) then
		for i,k in ipairs(keys) do
			table.remove(tab, k);
		end
		collectgarbage();
	end

	-- return number of "records" affected
	return numRecords;
end

-- COPY ----------------------------------------------------------------------
-- tab    : (table) target table
-- where  : (table) expects an associative table of {key = value} pairs for search criteria (source record)
-- where2 : (table) expects an associative table of {key = value} pairs for search criteria (destination record)
-- any    : (boolean) if true, allows partial matching. works like sql's "OR" syntax
FI_DB.copy = function( tab, where, where2, any )
	local source = FI_DB.select(tab, where, true);
	local keys = FI_DB.find(tab, where2, nil, any);

	if (#keys > 0) then
		-- iterate over each target record
		for i,key in ipairs(keys) do
			-- save the ID before we overwrite the record
			local id = tab[key]["id"];
			-- copy entire source record over destination
			tab[key] = LIB.table.copy(source);
			-- restore the original record id
			tab[key]["id"] = id;
		end
	end

	-- return table indexes of destination records found/changed
	return keys;
end

-- "tail" wrapper
FI_DB.first = function( tab, where, orderby )
	return FI_DB.tail(tab, where, orderby, "desc");
end

-- "tail" wrapper
FI_DB.last = function( tab, where, orderby )
	return FI_DB.tail(tab, where, orderby, "asc");
end

-- this is meant to help "tail" the farming log
FI_DB.tail = function( tab, where, orderby, order )
	if FI_SV_CONFIG.debug then print("FI_DB.tail in progress..."); end

	-- build data set
	local keys = FI_DB.find(tab, where);

	if keys[1] then
		-- prep for sort
		local k = keys[1];
		local temp = LIB.table.copy(tab[k]);
		
		for i,key in ipairs(keys) do
			-- this is probably only safe with numeric values at this point
			if (order == "asc") then
				if (tab[key][orderby] > temp[orderby]) then temp = LIB.table.copy(tab[key]); end
			elseif (order == "desc") then
				if (tab[key][orderby] < temp[orderby]) then temp = LIB.table.copy(tab[key]); end
			end
		end

		return temp;
	end
end

-- data caching service
-- tab (table): pointer to actual parent "database"
-- target (string): index of child table to be cached
-- returns: timestamps for debugging, etc.
FI_DB.cache = function( tab, target )
	local start = time();
	
	-- clear old data
	if FI_SVPC_CACHE[target] then
		FI_SVPC_CACHE[target] = nil;
		collectgarbage();
		FI_SVPC_CACHE[target] = {};
	end
	
	-- copy fresh data
	FI_SVPC_CACHE[target] = LIB.table.copy( tab[target] );
	
	return start,time();
end


--------------------------------------------------------------------------------
-- SESSION OBJECT
--------------------------------------------------------------------------------
FI_SESSION = {};

-- return the current session id
FI_SESSION.id = function( )
	-- id of zero means there are no records...
	return FI_DB.autoinc(FI_SVPC_DATA.Sessions)-1;
end

-- fetch the current session data
FI_SESSION.get = function( )
	local sid = FI_SESSION.id();
	return FI_DB.select(FI_SVPC_DATA.Sessions, {id = sid}, true);
end

-- determine if most recent session record is still open for use
FI_SESSION.active = function()
	local session = FI_SESSION.get();
	
	-- is the last session record still open?
	local result;
	if (session.start > 0) and (session.stop == 0) then 
		result = true;
	else
		result = false;
	end
	
	return result,session;
end

-- start a new session
FI_SESSION.start = function( )
	-- check existing session record
	local active,session = FI_SESSION.active();
	
	if active then
		-- end previous session
		session = FI_DB.update(FI_SVPC_DATA.Sessions, {id = session.id}, {stop = time()} );
	elseif (session.start == 0) then
		-- activate previous unused session
		session = FI_DB.update(FI_SVPC_DATA.Sessions, {id = session.id}, {start = time()} );
	else
		-- create new session
		local sid = FI_DB.insert(FI_SVPC_DATA.Sessions, FI_DEFAULTS.DB.Session);
		session = FI_DB.update(FI_SVPC_DATA.Sessions, {id = sid}, {start = time()} );
	end
	
	return session;
end

-- end the current session
FI_SESSION.stop = function( )
	local session = FI_SESSION.get();
	
	-- don't mess with sessions that are already timestamped
	if (session.stop == 0) then
		session = FI_DB.update(FI_SVPC_DATA.Sessions, {id = session.id}, {stop = time()} );
	end
	
	return session;
end

-- clear all session data
FI_SESSION.reset = function( )
	FI_SVPC_DATA.Sessions = {}
	collectgarbage();
	FI_SESSION.load();
end

-- startup routine
FI_SESSION.load = function( )
	-- check table
	if (FI_SVPC_DATA.Sessions == nil) then
		-- create missing table
		FI_SVPC_DATA.Sessions = {};
		FI_DB.insert(FI_SVPC_DATA.Sessions, FI_DEFAULTS.DB.Session);
	
	elseif (FI_SESSION.id() == 0) then
		-- table exists but it's empty...
		FI_DB.insert(FI_SVPC_DATA.Sessions, FI_DEFAULTS.DB.Session);
	end
	
	-- start your engines!
	FI_SESSION.start();
end

FI_SESSION.info = function( )
	local active,session = FI_SESSION.active();
	local output = {};
	
	output[1] = "Farming session status:";
	output[2] = "  Session ID:  "..session.id;
	output[3] = "  Session start time:  "..date("%c", session.start);
	local st;
	if (session.stop > 0) then
		st = date("%c", session.stop);
	else
		st = "n/a";
	end
	output[4] = "  Session stop time:  "..st;
	output[5] = "  Session is active:  "..strupper(tostring(active));
	
	FI_Message(output);
end


--------------------------------------------------------------------------------
-- DATA MAINTENANCE
--------------------------------------------------------------------------------
FI_DB.scan = function( context, source, target, repair )
	local results = {
		["missing"] = {},
		["errors"] = {},
	};
	
	if (context == "flat") then
		-- associative comparison (for data records)
		for i,key in pairs(LIB.table.keys(source)) do
			local fail = false;
			
			if (target[key] == nil) then
				-- missing key!
				table.insert(results.missing, key);
				fail = true;
				
			elseif (type(target[key]) ~= type(source[key])) then
				-- wrong data type
				table.insert(results.errors, key);
				fail = true;
			end
			
			if fail and repair then
				target[key] = source[key];
			end
		end
	
	elseif (context == "recursive") then
		-- recursive validation (for configuration settings, etc)
		for i,key in pairs(LIB.table.keys(source)) do
			local fail = false;
			
			if (target[key] == nil) then
				-- missing key
				table.insert(results.missing, key);
				fail = true;
			
			elseif (type(target[key]) ~= type(source[key])) then
				-- wrong data type
				table.insert(results.errors, key);
				fail = true;
			
			elseif (type(target[key]) == "table") then
				-- go down a level
				local res = FI_DB.scan("recursive", source[key], target[key], repair);
				
				if (#res.missing > 0) then
					results.missing[key] = res.missing;
					fail = true;
				end
				
				if (#res.errors > 0) then
					results.errors[key] = res.errors;
					fail = true;
				end
			end
			
			if fail and repair then
				if (type(source[key]) == "table") then
					target[key] = LIB.table.copy(source[key]);
				else
					target[key] = source[key];
				end
			end
		end
	end
	
	if FI_SV_CONFIG.debug and ((#results.missing > 0) or (#results.errors > 0)) then
		print("[FI_DB.validate]  Results:");
		table.dump(results);
	end
	
	return results;
end

FI_DB.check = function( arg, mode )
	local options = {
		-------------------------
		["Groups"] = "Group",
		["Buttons"] = "Button",
		["Currencies"] = "Currency",
		["Sessions"] = "Session",
		-------------------------
	}
	
	if options[arg] then
		-- check table
		if FI_SVPC_DATA[arg] then
			local database = FI_SVPC_DATA[arg];
			local schema = options[arg];
			local default = FI_DEFAULTS.DB[schema];
			
			local default_keys = {};
			for key,value in pairs(default) do
				table.insert(default_keys, key);
			end

			-- check records
			local results = {};
			
			for i,record in ipairs(database) do
				if (type(record) == "table") then
					results[i] = {
						["id"] = record.id,
					}
					
					-- check fields
					local fail;
					for i,key in pairs(default_keys) do
						if record[key] or (record[key] == false) then
							fail = false;
						else
							print("DB check failed on field:  "..key); table.dump(record); --exception
							fail = true; break;
						end
					end
					
					if fail then
						results[i]["result"] = "fail";
						
						FI_DB.rebuild(arg, i, schema);
					
					else
						results[i]["result"] = "pass";
					end
				
				else
					FI_DB.rebuild(arg, i, schema);
				end
			end
			
			if FI_SV_CONFIG.debug then 
				print("[DB Check]  '"..arg.."' deep scan complete."); --debug
			end
		
		elseif FI_SV_CONFIG.debug then
			print("[DB Check]  Table missing! Rebuilding '"..arg.."'"); --debug
			
			FI_DB.rebuild(arg);
		end
		
	elseif FI_SV_CONFIG.debug then
		 print("[DB Check]  Unknown argument: "..arg); --debug
	end
end

-- rebuild saved variable structure
FI_DB.rebuild = function( arg, index, schema )
	-- rebuild a specific record
	if index and schema then
		-- persist group id of buttons if possible
		local gid = 1;
		if (schema == "Button") and FI_SVPC_DATA[arg][index]["group"] then
			if (type(FI_SVPC_DATA[arg][index]["group"]) == "number") and (FI_SVPC_DATA[arg][index]["group"] > 0) then
				gid = FI_SVPC_DATA[arg][index]["group"];
			end
		end
		
		table.remove(FI_SVPC_DATA[arg], index);
		local rec_id = FI_DB.insert(FI_SVPC_DATA[arg], FI_DEFAULTS.DB[schema]);
		
		-- save group id
		if (schema == "Button") then
			FI_DB.update(FI_SVPC_DATA[arg], {id = rec_id}, {group = gid});
		end
	
	else
		-- misc addon data
		if (arg == "data") or (arg == "all") then
			FI_SV_DATA = {};
			FI_SVPC_DATA = {};

			FI_SV_DATA = LIB.table.copy( FI_DEFAULTS.SV.DATA );
			FI_SVPC_DATA = LIB.table.copy( FI_DEFAULTS.SVPC.DATA );
			FI_SVPC_CACHE = LIB.table.copy( FI_DEFAULTS.SVPC.CACHE );
		end
		
		-- configuration settings
		if (arg == "config") or (arg == "all") then
			FI_SV_CONFIG = {};
			FI_SVPC_CONFIG = {};
			
			FI_SV_CONFIG = LIB.table.copy( FI_DEFAULTS.SV.CONFIG );
			FI_SVPC_CONFIG = LIB.table.copy( FI_DEFAULTS.SVPC.CONFIG );
		end
		
		-- colors
		if (arg == "colors") then
			FI_SV_CONFIG.Colors = {};
			FI_SV_CONFIG.Colors = LIB.table.copy( FI_DEFAULTS.SV.CONFIG.Colors );
		end

		-- visual style data
		if (arg == "style") or (arg == "all") then
			FI_SVPC_STYLE = {};
			FI_SVPC_STYLE = LIB.table.copy( FI_STYLES.default );
		end
		
		-- frame data only
		if (arg == "frames") or (arg == "all") then
			FI_SVPC_DATA["Groups"] = {};
			FI_SVPC_DATA["Buttons"] = {};
			
			----- build group data -----
			for i=1,FI_DEFAULTS.NumGroups do
				FI_DB.insert(FI_SVPC_DATA.Groups, FI_DEFAULTS.DB.Group);
			end

			for i,group in ipairs(FI_SVPC_DATA.Groups) do
				----- build button data -----
				for n=1,FI_DEFAULTS.NumButtons do
					-- insert button data
					local bid = FI_DB.insert(FI_SVPC_DATA.Buttons, FI_DEFAULTS.DB.Button);
					-- assign button to group
					FI_DB.update(FI_SVPC_DATA.Buttons, {id = bid}, {group = group.id});
				end
			end
		end
		
		-- special data types only
		if (arg == "currencies") or (arg == "all") then
			if FI_SV_CONFIG.debug then print("Rebuilding [Currencies] table..."); end

			FI_SVPC_DATA["Currencies"] = {};
			
			for i=1,3 do
				FI_DB.insert(FI_SVPC_DATA.Currencies, FI_DEFAULTS.DB.Currency);
			end
			
			--if FI_SV_CONFIG.debug then table.dump(FI_SVPC_DATA.Currencies); end
		end
		
		if (arg == "sessions") or (arg == "all") then
			if FI_SV_CONFIG.debug then print("Rebuilding [Currencies] table..."); end

			FI_SVPC_DATA["Sessions"] = {};
		end
	end
end

FI_DB.garbage = function( action, arg )
	-- truncate log tables
	if (action == "all") or (action == "logs") then
		-- (temporary) empty the update log so it doesn't get too big
		FI_SV_DATA.Log = {};
	end
	
	-- police for orphaned data records (sorry little Annie)
	-- check for groups with no buttons
	-- check for buttons with no group id
	if (action == "all") or (action == "records") then
		
	end
	
	-- check size of user created data, such as the templates table
	-- warn user if too large
	if (action == "all") or (action == "user") then
		
	end
end
