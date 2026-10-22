---> Module manager
-- A basic module manager that holds all modules.


-- adds a module to the manager, returns the module
function lua_party.module_manager:Register(module)
    assert(getmetatable(module) == MODULE, "can only register modules made with MODULE:New")

    if self.by_name[module.name] then
        lua_party.fn.warn(string.format("module %s is already registered, replacing it", module.name), "lua party | module manager")
        self:Unregister(module.name)
    end

    self.modules[#self.modules + 1] = module
    self.by_name[module.name] = module

    return module
end

-- removes a module, disabling it first
function lua_party.module_manager:Unregister(name)
    local module = self.by_name[name]
    if not module then return false end

    if module.enabled then
        module.enabled = false
        module:OnDisable()
    end

    self.by_name[name] = nil
    for i, m in ipairs(self.modules) do
        if m == module then
            table.remove(self.modules, i)
            break
        end
    end

    return true
end

---> getters

function lua_party.module_manager:Get(name)
    return self.by_name[name]
end

function lua_party.module_manager:GetAll()
    return self.modules
end

function lua_party.module_manager:Count()
    return #self.modules
end

-- returns every module where filter(module) is true
function lua_party.module_manager:Filter(filter)
    local out = {}
    for _, module in ipairs(self.modules) do
        if filter(module) then
            out[#out + 1] = module
        end
    end
    return out
end

function lua_party.module_manager:GetEnabled()
    return self:Filter(function(m) return m.enabled end)
end

function lua_party.module_manager:GetDisabled()
    return self:Filter(function(m) return not m.enabled end)
end

function lua_party.module_manager:GetByCategory(category)
    return self:Filter(function(m) return m.category == category end)
end

function lua_party.module_manager:GetByRisk(risk)
    return self:Filter(function(m) return m.risk == risk end)
end

-- returns { Combat = {...}, Movement = {...}, ... } in enum order, handy for menus
function lua_party.module_manager:GetGroupedByCategory()
    local out = {}
    for _, category in ipairs(lua_party.enums.categories) do
        out[category] = self:GetByCategory(category)
    end
    return out
end

---> state by name

function lua_party.module_manager:Enable(name)
    local module = self.by_name[name]
    if not module then return false end

    module:Enable()
    return true
end

function lua_party.module_manager:Disable(name)
    local module = self.by_name[name]
    if not module then return false end

    return module:Disable()
end

-- returns the new enabled state, or nil if the module doesn't exist
function lua_party.module_manager:Toggle(name)
    local module = self.by_name[name]
    if not module then return nil end

    return module:Toggle()
end

-- disables everything that can be disabled
function lua_party.module_manager:DisableAll()
    for _, module in ipairs(self.modules) do
        module:Disable()
    end
end

-- disables every module with this risk level
function lua_party.module_manager:DisableByRisk(risk)
    for _, module in ipairs(self:GetByRisk(risk)) do
        module:Disable()
    end
end

---> dispatch

-- calls module:event(...) on every enabled module that has it.
function lua_party.module_manager:Dispatch(event, ...)
    local result

    for _, module in ipairs(self.modules) do
        local fn = module.enabled and module[event]
        if fn then
            local ok, ret = pcall(fn, module, ...)
            if not ok then
                lua_party.fn.err(string.format("%s:%s errored: %s", module.name, event, tostring(ret)), "lua party | module manager")
            elseif result == nil and ret ~= nil then
                result = ret
            end
        end
    end

    return result
end
