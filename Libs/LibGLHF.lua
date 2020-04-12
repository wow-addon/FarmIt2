--------------------------------------------------------------------------------
--  Generic Lua Helper Functions
--  Author: CHiLLZ <chillz@gmail.com>
--  Copyright 2006-2015, all rights reserved.
--  Version: 1.3
--
--  Functions meant to make life a little easier when coding in Lua.
--
--------------------------------------------------------------------------------

-- declare the main library "object"
LIB = {};

--------------------------------------------------------------------------------

LIB.table = {};

-- print() wrapper. Builds a recursive view of a table.
-- First argument is the target table to be viewed.
-- Second argument allows custom indentation.
LIB.table.print = function( tab, indent )
	if tab and (type(tab) == "table") then
		local pad = "  ";
		
		if indent then indent = indent..pad; else indent = ""; end

		for key,val in pairs(tab) do
			local t = type(val);
			
			print(indent..key.." ("..t..") = "..tostring(val));
			
			if (t == "table") then
				LIB.table.print(val, indent);
			end
		end
	
	else
		-- some light validation
		return "Input error. Expected table, got "..type(tab)..".";
	end
end

-- Copy a table by value, not by reference. *sigh*
LIB.table.copy = function( tab )
	local result = {};
	
	for key,val in pairs(tab) do
		if (type(val) == "table") then
			-- recursive call. why? because we love having to do this crap, thats why.
			result[key] = LIB.table.copy(val);
		else
			result[key] = val;
		end
	end
	
	-- uncomment if metatables are needed:
	--result = setmetatable(result, getmetatable(tab));
	
	return result;
end

-- Returns a sorted array of table keys.
LIB.table.keys = function( tab, ordered )
	local results = {};
	
	for key,val in pairs(tab) do
		table.insert(results, key);
	end
	
	if ordered then
		table.sort(results);
	end
	
	return results;
end

--------------------------------------------------------------------------------

-- Expects a decimal number. Second argument sets the precision.
-- If no second argument, rounds up to the nearest whole.
LIB.round = function( n, p )
	if (p == nil) then
		return math.floor(n + 0.5);
	else
		return math.floor( (n * 10^p) + 0.5) / (10^p);
	end
end

-- Shortens large numbers. Returns "E" on error.
-- input (num) : Required, expects whole number.
-- precision (num) : How many decimal places to include
-- limit (num) : How long the number can be before it is converted.
-- numonly (bool) : If true, output short number *without* a suffix.
LIB.ShortNum = function( input, precision, limit, numeric )
	local n,output;
	
	-- input validation
	if (input == nil) then
		return;
	else 
		n = tonumber(input);
	end
	
	-- decimal places
	local prec;
	if (precision == nil) then
		-- default precision
		prec = 2;
	else
		prec = tonumber(precision);
	end
	
	-- length threshold
	local maxlen = 3;
	local numlen = string.len(n);
	if (limit ~= nil) then
		maxlen = tonumber(limit);
		-- return the original number
		if (numlen <= maxlen) then return n; end
	end
	
	-- do the conversion
	local result,suffix;
	if (numlen < 4) and (maxlen > 3) then
		result = n;
		suffix = "";
	elseif (numlen > maxlen) then
		if (numlen < 7) then
			result = (n / 1000);
			suffix = "k";
		elseif (numlen < 10) then
			result = (n / 1000000);
			suffix = "M";
		elseif (numlen < 13) then
			result = (n / 1000000000);
			suffix = "B";
		elseif (numlen < 16) then
			result = (n / 1000000000000);
			suffix = "T";
		end
	end
	
	-- round to required precision
	local short = LIB.round(result,prec);
	
	-- formatting
	if numeric then
		output = short;
	else
		output = short..suffix;
	end
	
	return output;
end

-- Expects a value that works as a boolean, returns opposite value.
LIB.toggle = function( value )
	if value then
		return false;
	else
		return true;
	end
end

-- translate a not nil boolean value into a human readable string
LIB.BoolToString = function( input, key )
	local readable,result;
	
	if (input == nil) then
		return;
	elseif input then
		readable = {"TRUE","ON","ENABLED","YES"};
	else
		readable = {"FALSE","OFF","DISABLED","NO"};
	end
	
	if key then
		result = readable[tonumber(key)];
	else
		-- default output format
		result = readable[1];
	end
	
	return result;
end

-- strsplit() wrapper that behaves more like PHP's explode()
LIB.explode = function( needle, haystack, limit, ... )
	local results = {};
	
	-- input validation
	local arg = {...};
	if (needle == nil) and (haystack == nil) and (#arg > 0) then 
		for i,chunk in ipairs(arg) do
			if (limit == nil) or (i <= tonumber(limit)) then
				table.insert(results, chunk);
			end
		end
	else
		local n,h = tostring(needle),tostring(haystack);
		if (string.len(n) > 0) and (string.len(h) > 1) then
			results = LIB.explode(nil,nil, limit, strsplit(n, h));
		end
	end
	
	return results;
end
