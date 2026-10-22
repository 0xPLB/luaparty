function lua_party.fn.theme_editor(window)
    -- the old editor's widgets are gone after a rebuild, so are their syncs
    lua_party.themes.syncs = {}

    local function bind(fn)
        lua_party.themes.syncs[#lua_party.themes.syncs + 1] = fn
    end

    local tabs = occ.group(window, "Style", "Settings")
    local style = tabs:GetPage("Style")

    -- a picker for a theme colour, edited in place, its animation kept in
    -- lua_party.theme_anims so themes save and load it
    local function color_picker(label, path, color, parent)
        local picker = occ.colorpicker(label, parent)

        bind(lua_party.config.link_picker(picker,
            function()
                return color, lua_party.theme_anims[path]
            end,
            function(new, anim)
                for i = 1, 4 do
                    color[i] = new[i]
                end
                lua_party.theme_anims[path] = anim
            end))
    end

    local sections = {}
    for name in pairs(occ.style) do
        sections[#sections + 1] = name
    end
    table.sort(sections)

    for _, name in ipairs(sections) do
        local section = occ.style[name]

        if type(section) == "table" and type(section[1]) == "number" then
            color_picker(name, name, section, style)
        elseif type(section) == "table" then
            local list = occ.expandable(name, style)

            local keys = {}
            for key in pairs(section) do
                keys[#keys + 1] = key
            end
            table.sort(keys)

            for _, key in ipairs(keys) do
                local entry = section[key]

                if type(entry) == "table" then
                    color_picker(key, name .. "." .. key, entry, list)
                elseif type(entry) == "number" then
                    local slider = occ.slider(key, list)

                    if key:find("time", 1, true) or key == "delay" then
                        slider:SetRange(0, 10)
                        slider:SetStep(0.05)
                        slider:SetDecimals(2)
                        slider:SetUnit("s")
                    else
                        slider:SetRange(0, math.max(100, entry * 2))
                        slider:SetStep(1)
                    end

                    slider:SetValue(entry)

                    slider:OnChange(function(self, value)
                        section[key] = value
                    end)

                    bind(function()
                        slider:SetValue(section[key])
                    end)
                end
            end
        end
    end

    lua_party.fn.save_panel(tabs:GetPage("Settings"), "Themes", lua_party.themes, "theme")
end
