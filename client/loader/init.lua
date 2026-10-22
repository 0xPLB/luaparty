
printf = lje.con_printf 

lua_party = lua_party or {
    fn = {},
    vars = {},
    enums = {},
    registry = {},
    module_manager = {
        modules = {},  -- list, keeps registration order
        by_name = {},  -- name -> module
    }
}

lua_party.enums.categories = {"Combat", "Movement", "Visuals", "Misc"}
lua_party.enums.risk = {"UNKNOWN","LOW", "MEDIUM", "HIGH"}

function lua_party.fn.info(str, tag)
    if tag then
        printf("[$#858585{%s}] %s", tag, str)
    else
        printf("[$#858585{lua party}] %s", str)
    end
end

function lua_party.fn.warn(str, tag)
    if tag then
        printf("[$#ccc65e{%s}] %s", tag, str)
    else
        printf("[$#ccc65e{lua party}] %s", str)
    end
end

function lua_party.fn.err(str, tag)
    if tag then
        printf("[$#ba3434{%s}] %s", tag, str)
    else
        printf("[$#ba3434{lua party}] %s", str)
    end
end

function lua_party.fn.require(path)
    if utils.is_state_client() then
        printf("[$#454545{lua party}] [$#dea909{init}] including $#707070{%s}", path)
    else
        printf("[$#454545{lua party}] [$#4caf50{init}] including $#707070{%s}", path)
    end

    lje.include(path)
end


lua_party.fn.require("client/utils/module.lua")
lua_party.fn.require("client/utils/module_manager.lua")
lua_party.fn.require("client/utils/config.lua")
lua_party.fn.require("client/utils/configs.lua")
lua_party.fn.require("client/utils/themes.lua")

for _, category in ipairs(lua_party.enums.categories) do
    for _, modfile in ipairs(lje.env.find_script_files("modules/" .. category:lower() .. "/*")) do
        lua_party.fn.require(modfile)
    end
end

-- before ui and hooks, both check it before drawing
if utils.is_state_client() then
    lua_party.fn.require("client/utils/render_guard.lua")
end

lua_party.fn.require("ui/init.lua")

if utils.is_state_client() then
    lua_party.fn.require("client/utils/hooks.lua")
end