# Подключение
Для подключения LuaBox, разместите его в корне проекта и вызовите следующий код: 
```lua
require("luabox")
```

# LuaBox.Package
Реализация пространств имен/пакетов для Lua.

Чтобы указать текущий пакет, используется конструкция:
```lua
package [[ Имя_пакета ]]
```
Можно указать вложенный пакет разделив имена точкой
```lua
package [[ Package.Subpackage ]]
```

Чтобы получить доступ к данным пакета, можно обратится к ним
указав полный путь до пакета:
```lua
local data = Package.Subpackage.Item
```
Или же импортировав его в текущий пакет
```lua
import [[ Package.Subpackage ]]
local data = Item
```
Можно указывать относительное имя импортируемого пакета
```lua
package [[ Package ]]
import [[ ~.Subpackage ]]
local data = Item
```

# LuaBox.Class
Реализация классов в Lua

Создание простого класса:
```lua
MyClass = class-function(this)
   -- class body
end
```

Создание статического класса
```lua
MyStaticClass = class.static-function(this)
   -- static class body
end
```

Пример класса
```lua
Keyboard = class-function(this)
   private.keyStates = {}
   private.triggered = false
   
   function public. getKeyStates()
       -- < ... >
   end

   function public. update()
       -- < ... >
   end

   function private. setKeyState(code, state)
       -- < ... >
   end
end
```

Создание класса способ 1:
```lua
local keyboard = Keyboard.new()
```

Создание класса способ 2:
```lua
local keyboard = Keyboard()
```

Наследование
```lua
local MyClass = Keyboard.extend-function(this)
    -- < ... >
end
```