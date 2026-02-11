-- Copyright (C) 2006, Eagle Dynamics.
-- Serialization module based on the sample from the book
-- "Programming in Lua" by Roberto Ierusalimschy. - Rio de Janeiro, 2003

module('Serializer', package.seeall)
mtab = { __index = _M }

local Factory = require('Factory')

function new(fout)
  return Factory.create(_M, fout)
end

function construct(self, fout)
  self.fout = fout
end

function basicSerialize(self, o)
  if type(o) == "number" then
    return o
  elseif type(o) == "boolean" then
    return tostring(o)
  elseif type(o) == "string" then-- assume it is a string
    return string.format("%q", o)
  else
	return "nil"
  end
end

-- Use third argument as a local table for saved table names accumulation
-- to avoid repeated serialization.
-- Данный вариант позволяет сериализовать таблицы с произвольными символьными ключами.

function serialize_failure_message(self,value,name)
	if name ~= nil then
		return "nil,--Cannot serialize a "..type(value).." :"..name.."\n"
	else
		return "nil,--Cannot serialize a "..type(value).."\n"
	end
end

function failed_to_serialize(self,value,name)
	self.fout:write(serialize_failure_message(self,value,name))
end

function serialize(self, name, value, saved)
  saved = saved or {}
  self.fout:write(name, " = ")
  if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
    self.fout:write(self:basicSerialize(value), "\n")
  elseif type(value) == "table" then
    if saved[value] then -- value already saved?
      self.fout:write(saved[value], "\n") -- use its previous name
    else
      saved[value] = name -- save name for next time
      self.fout:write("{}\n") -- create a new table
      for k,v in pairs(value) do -- serialize its fields
        local fieldname = string.format("%s[%s]", name, self:basicSerialize(k))
        self:serialize(fieldname, v, saved)
      end
    end
  else
	self:failed_to_serialize(value,name)
  end
end

local function next_key(self,table_begin,name,level)
	if  table_begin then
		return true
	end
	self.fout:write("\n" .. level .. "{\n") -- create a new table
	return true
end
local function end_table(self,table_begin,name,level)
	if not table_begin then -- empty table
		if level == "" then
			self.fout:write("{}\n")
		else
			self.fout:write("{},\n")
		end
	else
		if level == "" then
			self.fout:write(level .. "} -- end of "  .. name .. "\n")
		else
			self.fout:write(level .. "}, -- end of " .. name .. "\n")
		end
	end
end

-- Предполагается, что символьные ключи в таблицах являются идентификаторами Lua.
local function key_printer_simple(k)
	if type(k) == "number" then
		return string.format("[%s]", k)
	else
		return k
	end
end

-- Предполагается, что символьные ключи в таблицах не являются идентификаторами Lua, но не содержат апострофов.
local function key_printer_map(k)
	if type(k) == "number" then
		return string.format("[%s]", k)
	else
		return string.format("[%q]", k)
	end
end

-- наглядная и простая сериализация без экономии повторяющихся таблиц.
local function serialize_simple_impl(self, name, value, level , key_printer)
	if level == nil then level = "" end
    self.fout:write(level, name, " = ")
    if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
        self.fout:write(self:basicSerialize(value), ",\n")
    elseif type(value) == "table" then
		local table_begin = false
        for k, v in pairs(value) do -- serialize its fields
			table_begin = next_key(self,table_begin,name,level)
			serialize_simple_impl(self,key_printer(k),v,level .. '\t',key_printer)
        end
		end_table(self,table_begin,name,level)
    else
        self:failed_to_serialize(value, name)
    end
end

-- Предполагается, что символьные ключи в таблицах являются идентификаторами Lua.
function serialize_simple(self, name, value, level)
	return serialize_simple_impl(self,name, value, level,key_printer_simple)
end

-- Предполагается, что символьные ключи в таблицах не являются идентификаторами Lua, но не содержат апострофов.
function serialize_simple2(self, name, value, level)
	return serialize_simple_impl(self,name, value, level,key_printer_map)
end

-- serialization to string

local serialize_to_string_result

function add_to_string(str)
  serialize_to_string_result = serialize_to_string_result..str    
end --

function serialize_to_string(self, name, value)
  serialize_to_string_result = ""
  self:serialize_to_string_simple(name, value)
  return serialize_to_string_result
end -- func                              

function serialize_to_string_simple(self, name, value,level)
    local level   =  level or ""
    add_to_string(level..name.."=")
    if  type(value) == "number" or 
        type(value) == "string" or 
        type(value) == "boolean" then
        add_to_string(self:basicSerialize(value) .. ",\n")
    elseif type(value) == "table" then
        add_to_string("\n"..level.."{\n")
		
		local ipaired = {
		}
		for k,v in ipairs(value) do -- serialize its fields
			ipaired[k] = true
            self:serialize_to_string_simple(string.format("[%s]", k),v,level.."\t")
        end
        for k,v in pairs(value) do -- serialize its fields
			if ipaired[k] == nil then
				local key
				if type(k) == "number" then          key = string.format("[%s]"  , k)
				else                                      key = string.format("[%q]", k)         end
				self:serialize_to_string_simple(key,v,level.."\t")
			end
        end
        if level == "" then   add_to_string(level.."}\n")
        else                  add_to_string(level.."},\n") end
    else   
		add_to_string(self:serialize_failure_message(value,name))
    end
end -- func

function do_serialize_to_func(self, outfunc, name, value, level, mem)
	outfunc(level)
	outfunc(name)
	outfunc('=')
	if type(value) == "number" or 
           type(value) == "string" or 
	   type(value) == "boolean" then
		outfunc(self:basicSerialize(value))
		outfunc(",\n")
	elseif type(value) == "table" then
		if mem[value] then
			outfunc("nil,\n")
			return
		else
			mem[value] = true
		end
		--outfunc("\n")
		--outfunc(level)
		outfunc("{\n")
		local ipaired = {}
		for k,v in ipairs(value) do -- serialize its fields
			ipaired[k] = true
			self:do_serialize_to_func(outfunc, string.format("[%s]", k), v, level.."\t", mem)
		end
		for k,v in pairs(value) do -- serialize its fields
			if ipaired[k] == nil then
				local key
				if type(k) == "number" then
					key = string.format("[%s]", k)
				else
					key = string.format("[%q]", k)
				end
				self:do_serialize_to_func(outfunc, key, v, level.."\t", mem)
			end
		end
		outfunc(level)
		if level == "" then
			outfunc("}\n")
		else
			outfunc("},\n")
		end
	else   
		outfunc(self:serialize_failure_message(value,name))
	end
end -- serialize_to_func

function serialize_to_func(self, outfunc, name, value)
	local level = level or ""
	local mem = {}
	self:do_serialize_to_func(outfunc, name, value, level, mem)
end -- serialize_to_func

function serialize_to_string_noCR(self, name, value)
  serialize_to_string_result = ""
  self:serialize_to_string_simple_noCR(name, value)
  -- delete last ","
  return string.sub(serialize_to_string_result,1,string.len(serialize_to_string_result)-1)
end -- func                              

function serialize_to_string_simple_noCR(self, name, value)
  add_to_string(name.."=")
  if type(value) == "number" or type(value) == "string" or type(value) == "boolean" then
      add_to_string(self:basicSerialize(value) .. ",")
  elseif type(value) == "table" then
      add_to_string("{")
      for k,v in pairs(value) do -- serialize its fields
        local key
        if type(k) == "number" then
          key = string.format("[%s]", k)
        else
          key = string.format("[%q]", k)
        end
        self:serialize_to_string_simple_noCR(key, v)
      end
      add_to_string("},")
  else
      add_to_string(self:serialize_failure_message(value,name))
  end
end -- func

local function isSimpleTable(value)
    if value == nil or type(value) ~= "table" then
        return true
    end

    for k,v in pairs(value) do
        if type(v) == "table" or type(k) ~= "number" then return false end
    end
    return true
end

-- Аналогична serialize_simple но простые табилцы (не содержащие вложенных таблиц), записываются в одну строку в тщетной надежде повысить читаемость.


local forbidden_key =
{
 ["and"]		= true,
 ["break"]		= true,
 ["do"]			= true,
 ["else"]		= true,
 ["elseif"]		= true,
 ["end"]		= true,
 ["false"]		= true,
 ["for"]		= true,
 ["function"]	= true,
 ["if"] 		= true,
 ["in"] 		= true,
 ["local"] 		= true,
 ["nil"] 		= true,
 ["not"] 		= true,
 ["or"] 		= true,
 ["repeat"] 	= true,
 ["return"] 	= true,
 ["then"] 		= true,
 ["true"] 		= true,
 ["until"] 		= true,
 ["while"] 		= true,
}

function serialize_compact_iter(self, name, value, level,iterator_fn)
  local endOfLineSymb 
  if level == nil then 
	level = "" 
	endOfLineSymb = "\n"
  else
	endOfLineSymb = ",\n"
  end
  
  local v_type = type(value) 

  if v_type == "number"  or 
	 v_type == "string"  or 
	 v_type == "boolean" then
	self.fout:write(level, name, "\t=\t") 
	self.fout:write(self:basicSerialize(value), endOfLineSymb)
  elseif v_type == "table" then
	  self.fout:write(level, name, " = ") 
      if not isSimpleTable(value) then
          self.fout:write("\n"..level.."{\n") -- create a new table
          for k,v in iterator_fn(value) do -- serialize its fields
            local key
            if type(k) == "number" then      key = string.format("[%s]", k)
            elseif type(k) == "string" then
				local match_result = string.match(k,'[_%a][_%w]*')--match that is valid lua identifier
				
				local valid_variable_name =  match_result and match_result == k and  not forbidden_key[k]
				
				if valid_variable_name then
					key = k
				else
					key = string.format("[%q]", k)
				end
            else
				key = k
            end
            serialize_compact_iter(self, key, v, level..'\t',iterator_fn)
          end
		  
          if level == "" then	self.fout:write(level.."} -- end of "..name.."\n")
          else		            self.fout:write(level.."}, -- end of "..name.."\n")
          end
      else
          self.fout:write("\t{") -- create a new table
          for i,v in ipairs(value) do -- serialize its fields
            if (i == #value) then self.fout:write(self:basicSerialize(v)) 
            else self.fout:write(self:basicSerialize(v), ",\t")
            end
          end
          self.fout:write("}"..endOfLineSymb)
      end
  else
	self.fout:write(level, name, "\t=\t") 
	self:failed_to_serialize(value,name)
  end
end

function serialize_compact(self, name, value, level)
	serialize_compact_iter(self, name, value, level,pairs)
end

-- превращает таблицу в массив отсортированных по ключу пар [ключ, значение]
function getSortedPairs(tableValue)
  local result = {}
  
  for key, value in pairs(tableValue) do
    table.insert(result, {key = key, value = value})
  end
  
  local sortFunction = function (pair1, pair2) 
    return pair1.key < pair2.key 
  end
  
  table.sort(result, sortFunction)
  
  return result
end

-- сохраняет в файл таблицу, отсортированную по ключу 
-- это нужно для удобства сравнения сохраненных таблиц svn'ом, 
function serialize_sorted(self, name, value, level)
  local levelOffset = "\t"
  
  if level == nil then 
    level = "" 
  end
  
  -- if level ~= "" then 
    -- level = level .. levelOffset 
  -- end
  
  self.fout:write(level, name, " = ")
  
  local valueType = type(value)
  
  if valueType == "number" or 
     valueType == "string" or 
	 valueType == "boolean" then
    self.fout:write(self:basicSerialize(value), ",\n")
  elseif valueType == "table" then
      self.fout:write("{\n") -- create a new table
      
      local sortedPairs = getSortedPairs(value)
      
      for i, pair in pairs(sortedPairs) do
        local k = pair.key        
        local key
        
        if type(k) == "number" then
          key = string.format("[%s]", k)
        else
          key = string.format("[%q]", k)
        end
        
        self:serialize_sorted(key, pair.value, level .. levelOffset)    
      end

      if level == "" then
        self.fout:write(level.."}\n")
      else
        self.fout:write(level.."},\n")
      end
  else
     self:failed_to_serialize(value,name)
  end
end


function serialize_sortedX(self, name, value, level)
  local levelOffset = "\t"
  
  if level == nil then 
    level = "" 
  end
  
  self.fout:write(level, name, " = ")
  
  local valueType = type(value)
  
  if valueType == "number" or 
		valueType == "string" or 
		valueType == "boolean" then
		if level == "" then
			self.fout:write(self:basicSerialize(value), "\n")
		else
			self.fout:write(self:basicSerialize(value), ",\n")
		end
  elseif valueType == "table" then
      self.fout:write("{\n") -- create a new table
      
      local sortedPairs = getSortedPairs(value)
      
      for i, pair in pairs(sortedPairs) do
        local k = pair.key        
        local key
        
        if type(k) == "number" then
          key = string.format("[%s]", k)
        else
          key = string.format("[%q]", k)
        end
        
        self:serialize_sortedX(key, pair.value, level .. levelOffset)    
      end

      if level == "" then
        self.fout:write(level.."}\n")
      else
        self.fout:write(level.."},\n")
      end
  else
     self:failed_to_serialize(value,name)
  end
end

--пишет в корень а не в таблицу
function serialize_sorted_noTabl(self, value, level) 
	if level == nil then 
		level = "" 
	end

	local valueType = type(value)
  
	if valueType == "number" or 
		valueType == "string" or 
		valueType == "boolean" then
		self.fout:write(self:basicSerialize(value), "\n")
	elseif valueType == "table" then
      
		local sortedPairs = getSortedPairs(value)
      
		for i, pair in pairs(sortedPairs) do
			local k = pair.key        
	
			self:serialize_sortedX(k, pair.value, level)    
		end

    else
       self:failed_to_serialize(value)
    end
end

