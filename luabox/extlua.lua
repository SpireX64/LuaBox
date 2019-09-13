null = {}
setmetatable(null, {
  --__metatable = false;
 -- __newIndex = function() error("attempt to index null value",2);
  --__index = function() error("attempt to index null value",2);
 -- __type = "nil"
})

function split(inputstr, sep)
  if sep == nil then sep = "%s" end
  local t={}; local i=1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    t[i] = str:match "^%s*(.-)%s*$"; i = i + 1
  end
  return t
end

--# Type check for lua classes
local buildinType = _G.type;
local function CheckType(o)
  local result = buildinType(o);
  if result == 'table' and o.__type ~= nil then
    return o.__type;
  else
    return result;
  end;
end;
_G.type = CheckType;

--# UUID for class/inst identification
function newUuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

--# Clone table
function table.clone(target, source)
  for k,v in pairs(source) do target[k] = v end
end

function table.len(t)
  if(type(t) ~= 'table') then
    return 0;
  end;
  local count = 0;
  for k,v in pairs(t) do
    count = count + 1
  end;
  return count;
end

--# Print Table
function table.print(t)
  for k,v in pairs(t) do
    print(k, v);
  end
end