lua_party.config = {}

---> widgets keep their own state, so each one built for a setting leaves a
---> function here that sets it back from the module. configs.load runs them.
lua_party.config.syncs = {}

function lua_party.config.bind(fn)
    lua_party.config.syncs[#lua_party.config.syncs + 1] = fn
end

-- puts every bound widget back in line with its module
function lua_party.config.sync()
    for _, fn in ipairs(lua_party.config.syncs) do
        local ok, err = pcall(fn)
        if not ok then
            lua_party.fn.err("widget sync failed: " .. tostring(err), "lua party | config")
        end
    end
end

-- where a colorpicker setting keeps its animation
function lua_party.config.animkey(key)
    return key .. "#anim"
end

function lua_party.config.link_picker(picker, read, write)
    picker:OnChange(function(self, color)
        local anim
        local mode = self:GetAnimation()

        if mode ~= "none" then
            local h, s, v = self:GetHSV()
            anim = {mode = mode, rate = self:GetRate(), base = {h, s, v, self:GetColorAlpha()}}
        end

        write({color[1], color[2], color[3], color[4]}, anim)
    end)

    local function apply()
        -- read and copy before the setters below fire OnChange and overwrite it
        local color, anim = read()
        color = {color[1], color[2], color[3], color[4]}

        if anim then
            anim = {mode = anim.mode, rate = anim.rate, base = {unpack(anim.base)}}

            picker:SetRate(anim.rate)
            picker:SetHSV(anim.base[1], anim.base[2], anim.base[3])
            picker:SetColorAlpha(anim.base[4])
            picker:SetAnimation(anim.mode)
        else
            picker:SetAnimation("none")
            picker:SetColor(occ.color(unpack(color)))
        end

        -- a setter that changed nothing doesn't fire, so write it out once
        picker:OnChange(picker:GetColor())
    end

    apply()

    return apply
end

lua_party.config.widgets = {
    checkbox = function(module, entry, parent)
        local box = occ.checkbox(entry.name, parent)
        box:SetChecked(module.settings[entry.key])

        function box:OnChange(checked)
            module.settings[entry.key] = checked
        end

        lua_party.config.bind(function()
            box:SetChecked(module.settings[entry.key])
        end)

        return box
    end,

    slider = function(module, entry, parent)
        local slider = occ.slider(entry.name, parent)
        slider:SetRange(entry.min, entry.max)
        slider:SetStep(entry.step or 1)
        slider:SetDecimals(entry.decimals or 0)
        slider:SetUnit(entry.unit or "")
        slider:SetValue(module.settings[entry.key])

        slider:OnChange(function(self, value)
            module.settings[entry.key] = value
        end)

        lua_party.config.bind(function()
            slider:SetValue(module.settings[entry.key])
        end)

        return slider
    end,

    dropdown = function(module, entry, parent)
        local dropdown = occ.dropdown(entry.name, parent, entry.options)
        dropdown:SetMultiple(entry.multiple == true)

        if entry.multiple then
            for _, option in ipairs(module.settings[entry.key]) do
                dropdown:Pick(option)
            end
        else
            dropdown:Pick(module.settings[entry.key])
        end

        dropdown:OnChange(function(self)
            if entry.multiple then
                local _, texts = self:GetPickedAll()
                module.settings[entry.key] = texts
            else
                local _, text = self:GetPicked()
                module.settings[entry.key] = text
            end
        end)

        lua_party.config.bind(function()
            local value = module.settings[entry.key]

            if entry.multiple then
                local wanted = {}
                for i, option in ipairs(value or {}) do wanted[i] = option end

                dropdown:Clear()
                for _, option in ipairs(wanted) do dropdown:Pick(option) end
            elseif value ~= nil then
                dropdown:Pick(value)
            else
                dropdown:Clear()
            end
        end)

        return dropdown
    end,

    colorpicker = function(module, entry, parent)
        local animkey = lua_party.config.animkey(entry.key)
        local picker = occ.colorpicker(entry.name, parent)

        local apply = lua_party.config.link_picker(picker,
            function()
                return module.settings[entry.key], module.settings[animkey]
            end,
            function(color, anim)
                module.settings[entry.key] = color
                module.settings[animkey] = anim
            end)

        lua_party.config.bind(apply)

        return picker
    end,
}

function MODULE:config(entries)
    for _, entry in ipairs(entries) do
        assert(lua_party.config.widgets[entry.type],
            string.format("module %s has invalid config type: %s", self.name, tostring(entry.type)))

        entry.key = entry.key or entry.name
        self.configs[#self.configs + 1] = entry
        self.settings[entry.key] = entry.default
    end

    return self
end

function MODULE:get(key)
    return self.settings[key]
end

function MODULE:set(key, value)
    self.settings[key] = value
end
