--- @Module class
local LuaClass = {}
local ClassFabric = {}
local ClassProxy = nil

--# ==================================================================================================
--# - Class Patterns
--# ==================================================================================================

local ClassPattern = {}
function ClassPattern.ExtendScope(pattern, base)
  if getfenv then setmetatable(pattern, {__index = base or getfenv(3)});
  else setmetatable(pattern, {__index = base or _G}) end
  return pattern;
end;

function ClassPattern.Static(base)
  return ClassPattern.ExtendScope ({
    public = {};
    private = {};
  }, base)
end;

function ClassPattern.General(base)
  return ClassPattern.ExtendScope( {
    public = {};
    private = {};
    protected = {};
    static = ClassPattern.Static();
  }, base)
end;

function ClassPattern.Data()
  return ClassPattern.ExtendScope({});
end;

--# ==================================================================================================
--# - Instance Fabric
--# - [Step 4] - Make class-instance fabric
--# ==================================================================================================

local function InstanceFabric_General(classData, def)
  return function(...)
    local instance = ClassPattern.General();
    
    if(type(classData.extendData) == 'table') then
      setmetatable(instance.public, {__index = classData.extendData.public})
      setmetatable(instance.protected, {__index = classData.extendData.protected})
    end;
    
    def(instance);
    instance.static = classData.static;
    
    local class = classData.static.public;
    if type(instance.constructor) == 'function' then
      instance.constructor(...);
    end
    
    instance = instance.public;
    
    instance.__uuid = newUuid();
    instance.__type = "class#" .. class.__uuid;
    
    setmetatable(instance, {
      __metatable = false;
      __newindex = function(t,k,v)
        -- SetFor Class
        local typedef = type(class[k]);
        if(typedef ~= 'nil' and typedef ~= 'function') then
          rawset(class, k, v);
          return
        end;
        -- SetFor Instance
        typedef = type(instance[k]);
        if(typedef ~= 'nil' and typedef ~= 'function') then
          rawset(instance, k, v);
        end;
        error("attempt to index class field '" .. k .. "'",2);
      end;
      __index = function(_,k)
        if(classData.extendData ~= nil) then
          local value = classData.extendData.public[k];
          if(value ~= nil) then return value end;
        end;
        return class[k];
      end;
    });
    return instance
  end;
end;

local function InstanceFabric_Data(class, def)
  return function(...)
    local instance = {};
    table.clone(instance,def);
    
    local args = ...;
    local argCount = table.len(args);
    if argCount > 0 then
      for k,v in pairs(args) do
        local t = type(instance[k])
        if t ~= 'nil' and t ~= 'function' then
          instance[k] = args[k];
        end
      end
    end
    
    instance.__uuid = newUuid();
    instance.__type = "class#" .. class.__uuid;
    
    setmetatable(instance, {
      __metatable = false;
      __index = class;
      __newindex = function(t,k,v)
        -- SetFor Class
        local typedef = type(class[k]);
        if(typedef ~= 'nil' and typedef ~= 'function') then
          rawset(class, k, v);
          return
        end;
        -- SetFor Instance
        typedef = type(instance[k]);
        if(typedef ~= 'nil' and typedef ~= 'function') then
          rawset(instance, k, v);
          return
        end;
        error("attempt to index class field '" .. k .. "'",2);
      end;
    })
    
    return instance;
  end
end

--- @function [parent=#class] InstanceFabric_New
-- Создает экземпляр анонимного класса из таблицы
local function InstanceFabric_New(def)
  local instance = def;
  instance.__uuid = newUuid()
  instance.__type = "class#" + instance.__uuid
  setmetatable(instance, {
    __metatable = false;
    __newindex = function(t,k,v)
      local typedef = type(instance[k]);
      if(typedef ~= 'nil' and typedef ~= 'function') then
        rawset(instance, k, v)
      else
        error("attempt to index instance field '" .. k .. "'",2);
      end
    end
  })
  return instance
end

--- @function [parent=#class] InstanceFabric
-- Фабричный метод генерирующий метод для создания
-- новых экземпляров класса
-- @param #table class Базовый класс экземпляра
-- @param def Функция или таблица определения класса
-- @param #table opt Опции генерации класса
-- - final - Запрет на наследование класса
-- - new - Может создавать экземпляры
-- - data - Определение класса является таблицей
-- @return #function Конструктор экземпляра класса
local function InstanceFabric(class, def, opt) --> instance_constructor
  if(opt.data == true) then
    return InstanceFabric_Data(class, def)
  else 
    return InstanceFabric_General(class, def)
  end;
end

--# ==================================================================================================
--# - Class Extend Fabric
--# - [STEP 5] - Make extend support for general class
--# ==================================================================================================

--- @function [parent=#class] ExtendClassFabric
-- Фабричный метод для реализации наследования класса
-- @param #table baseData Данные базового класса
-- @return #function Функция наследования класса
local function ExtendClassFabric(baseData)
  local extend = {}
  setmetatable(extend, {
    __sub = function(_,def)
      local classData = ClassPattern.General();
      -- Наследуем public и protected члены класса
      
      classData.extendData = {
        public = baseData.public;
        protected = baseData.protected;
      }
    
      setmetatable(classData.public, {__index = baseData.public});
      setmetatable(classData.protected, {__index = baseData.protected});
      setmetatable(classData.static.public, {__index = baseData.static.public});
      def(classData);
      
      classData.static.public.__uuid = newUuid();
      
      return ClassProxy(classData, def,{
        final = false,
        new = true,
        data = false
      });
    end;
  });
  return extend;
end;

--# ==================================================================================================
--# - Class Proxy Fabric
--# - [STEP 3] - Make Proxy containter for class access
--# ==================================================================================================

--- @function [parent=#class] ClassProxy
-- Создает Proxy-контейнер для доступа к классу
-- и его специальным методам вроде 'new()' или 'extend()'
-- @param #table classData Данные класса
-- @param def Таблица или функция определения класса
-- @param #table opt Опции генерации класса
-- - final - Запрет на наследование класса
-- - new - Может создавать экземпляры
-- - data - Определение класса является таблицей 
ClassProxy =  function(classData, def, opt)
  local class = {};
  
  if(opt.new == true) then
    -- General Class
    if(opt.data == true) then
      class = classData;
    else
      class = classData.static.public
    end;
  else
    if(opt.data == true) then
      class = classData
    else
      class = classData.public
    end
  end
  
  local proxy = {
      __type = "class#" .. class.__uuid;
  };
  
  local proxy_mt = {
    __index = class;
    __newindex = function(t,k,v)
        local typedef = type(class[k]);
        if(typedef ~= 'nil' and typedef ~= 'function') then
          rawset(class, k, v);
          return
        end;
        error("attempt to index class field '" .. k .. "'",2);
      end;
  };
  
  if opt.new == true then
    local instanceConstructor = InstanceFabric(classData, def, opt);
    proxy.new = instanceConstructor;        -- a = Class.new(...)
    proxy_mt.__call = function(_,...) return instanceConstructor(...) end;  -- a = Class(...)
  else
    proxy.new = function() error("attempt to create instance of static class",2) end
    proxy_mt.__call = proxy.new
  end
  
  if(opt.final == false) then
    -- Class extend support
    proxy.extend = ExtendClassFabric(classData);
  end;
  
  setmetatable(proxy, proxy_mt);
  return proxy;
end;

--# ==================================================================================================
--# - Class Fabric
--# - [STEP 2] - Generate base pattern for class
--# ==================================================================================================

function ClassFabric.General(def)
  local classData = ClassPattern.General();
  def(classData);
  classData.static.public.__uuid = newUuid();
  
  return ClassProxy(classData, def,{
    final = false,
    new = true,
    data = false
  });
end;

function ClassFabric.GeneralData(def)
  local class = {};
  class.__uuid = newUuid();
  
  return ClassProxy(class, def, {
    final = false;
    new = true;
    data = true;
  });
end;

function ClassFabric.Static(def)
  local staticData = ClassPattern.Static();
  def(staticData);
  staticData.public.__uuid = newUuid()
  return ClassProxy(staticData, def, {
    final = false,
    new = false,
    data = false
  })
end;

function ClassFabric.StaticData(def)
  local staticData = ClassPattern.Data();
  staticData.__uuid = newUuid();
  
end;

--# ==================================================================================================
--# - Class Module
--# - [STEP 1] - Use 'LuaClass Module' for create new class
--# ==================================================================================================

LuaClass.new = function(def)
  if type(def) ~= 'table' then
    return InstanceFabric_New(def)
  else
    error("Unsuppored definition in 'class.new {}'",2)
  end
end

LuaClass.static = {};
setmetatable(LuaClass.static, {
  __sub = function(_, def)
    -- Static class creation
    local defType = type(def);
    if defType == "function" then
      return ClassFabric.Static(def);
    else
      error("Error: Unsupported definition in 'class.static-function'",2)
    end;
  end;
  
  __call = function(_, def)
    local defType = type(def);
    if defType == "table" then
      return ClassFabric.StaticData(def);
    else 
      error("Error: Unsupported definition in 'class.static {}'",2)
    end;
  end;
});

setmetatable(LuaClass, {
  __sub = function(_, def)
    -- General class creation
    local defType = type(def);
    if defType == "function" then
      return ClassFabric.General(def);
    else
      error("Error: Unsupported definition in class-function",2)
    end;
  end;
  
  __call = function(_, def)
    local defType = type(def);
    if defType == "table" then
      return ClassFabric.GeneralData(def);
    else 
      error("Error: Unsupported definition in class {}",2)
    end;
  end;
});

return LuaClass;