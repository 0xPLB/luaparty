---> module.lua

MODULE = {}
MODULE.__index = MODULE

function MODULE:New(data)
    assert(type(data) == "table", "module data must be a table")
    assert(type(data.name) == "string", "module needs a name")
    assert(utils.in_enum(lua_party.enums.categories, data.category),
        string.format("module %s has invalid category: %s", data.name, tostring(data.category)))
    assert(utils.in_enum(lua_party.enums.risk, data.risk),
        string.format("module %s has invalid risk: %s", data.name, tostring(data.risk)))

    local obj = setmetatable({}, self)
    obj.name = data.name
    obj.description = data.description or ""
    obj.category = data.category
    obj.subcategory = data.subcategory
    obj.tag = data.tag
    obj.risk = data.risk
    obj.enabled = data.enabled == true
    obj.can_disable = data.can_disable ~= false
    obj.configs = {}
    obj.settings = {}

    return obj
end

---> override these on a module to run code when its state changes
function MODULE:OnEnable() end
function MODULE:OnDisable() end

function MODULE:IsEnabled()
    return self.enabled
end

function MODULE:Enable()
    if self.enabled then return end

    self.enabled = true
    self:OnEnable()
end

-- returns false if the module can't be disabled
function MODULE:Disable()
    if not self.enabled then return true end

    if not self.can_disable then
        return false
    end

    self.enabled = false
    self:OnDisable()
    return true
end

function MODULE:Toggle()
    if self.enabled then
        self:Disable()
    else
        self:Enable()
    end

    return self.enabled
end
