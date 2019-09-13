--- @module module 

local PackageModule = {};
local PackageRepository = {};
setmetatable(PackageRepository,{__index = _G})

--# =============================================================================
--# - Package methods
--# =============================================================================

local function findPackage( path , root)
  local package = PackageRepository;
  if(path[1] == '~') then package = root or package; end
  for _,node in ipairs(path) do
    if(node ~= '~') then 
      package = package[node]
      if package == nil then break end
    end;
  end
  return package
end

local function package_getname(p)
  return p.__name;
end

local function package_import(p, path)
  local package = findPackage(split(path,'.'),p);
  if type(package) == "table" and package ~= p then
    table.insert(p.__import, package);
  end 
end

--# =============================================================================
--# -
--# =============================================================================

local function emptyPackage( name )
  local package = {
    _G = _G;
    __name = name;
    __import = {};
    import = package_import;
    modulename = package_getname;
  }
  package.self = package
  
  setmetatable(package, {
    __index = function(t,k)
      local val = nil
      for _, pack in ipairs(t.__import) do
        val = pack[k];
        if val ~= nil then break end
      end
      if val ~= nil then return val
      else return PackageRepository[k] end
    end
  });
  return package
end

local function createPackage( path )
  local package = nil;
  local root = PackageRepository;
  for _,node in ipairs(path) do
    package = root[node]
    if package == nil then
      package = emptyPackage(node)
      root[node] = package
    end
    root = package
  end
  return package
end

function defineFilePackage( packagePath )
  local path = split(packagePath,'.');
  return createPackage(path);
end


function PackageModule.require(package, path)
  local packageEnv = defineFilePackage(package)
  setmetatable(packageEnv, {__index = require(path)})
end

setmetatable(PackageModule, {
  __call = function(_, package)
    p =  defineFilePackage(package)
    if setfenv then setfenv(2, p) end
    return p
  end;
});

return PackageModule;