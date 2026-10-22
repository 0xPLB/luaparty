---> savePanel.lua

function lua_party.fn.save_panel(parent, title, api, kind)
    local group = occ.group(parent):SetText(title)

    -- empty until something has been saved
    local picker = occ.dropdown(kind:sub(1, 1):upper() .. kind:sub(2), group, api.list())
    picker:Pick(1)

    local function save(name)
        local ok, err = api.save(name)
        occ.notification(ok and ("Saved " .. name) or ("Save failed: " .. tostring(err)), 3)

        if ok then
            picker:SetOptions(api.list())
            picker:Pick(name)
        end
    end

    occ.button("Load", group):OnClick(function()
        local _, name = picker:GetPicked()

        if not name then
            occ.notification("Pick a " .. kind .. " to load", 3)
            return
        end

        local ok, err = api.load(name)
        occ.notification(ok and ("Loaded " .. name) or ("Load failed: " .. tostring(err)), 3)
    end)

    -- overwrites the picked one, or makes the first one if there are none
    occ.button("Save", group):OnClick(function()
        local _, name = picker:GetPicked()
        save(name or api.new_name())
    end)

    occ.button("New", group):OnClick(function()
        save(api.new_name())
    end)

    return group
end
