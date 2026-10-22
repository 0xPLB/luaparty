occ.clear()

local nav = occ.navbar({"Configurations", "Environment", "Activity", "Theme"})

local configurations = nav:GetWindow("Configurations")
configurations:SetSize(450, 600)

nav:GetWindow("Environment"):SetSize(300, 200)
nav:GetWindow("Activity"):SetSize(300, 200)

local theme = nav:GetWindow("Theme")
theme:SetSize(250, 400)

lua_party.fn.require("ui/widgets/savePanel.lua")
lua_party.fn.require("ui/widgets/themeEditor.lua")
lua_party.fn.theme_editor(theme)

local main = occ.group(configurations, unpack(lua_party.enums.categories))

for _, category in ipairs(lua_party.enums.categories) do
    local page = main:GetPage(category)
    local groups = {}

    for _, module in ipairs(lua_party.module_manager:GetByCategory(category)) do
        local key = module.tag or module.name

        if groups[key] then
            groups[key]:AddTab(module.name)
        else
            groups[key] = occ.group(page, module.name)
        end

        local tab = groups[key]:GetPage(module.name)

        local box = occ.checkbox("Enabled", tab)
        box:SetChecked(module.enabled)

        local settings = {}

        for _, entry in ipairs(module.configs) do
            local widget = lua_party.config.widgets[entry.type](module, entry, tab)
            widget:SetVisible(module.enabled)
            settings[#settings + 1] = widget
        end

        function box:OnChange(checked)
            if checked then
                module:Enable()
            else
                module:Disable()
                self:SetChecked(module.enabled)
            end

            for _, widget in ipairs(settings) do
                widget:SetVisible(module.enabled)
            end
        end

        -- a loaded config can turn the module on or off
        lua_party.config.bind(function()
            box:SetChecked(module.enabled)
        end)
    end
end

main:AddTab("Settings")

local settingspage = main:GetPage("Settings")

lua_party.fn.save_panel(settingspage, "Configuration", lua_party.configs, "config")
