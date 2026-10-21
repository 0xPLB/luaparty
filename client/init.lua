printf = lje.con_printf 

lua_party = {
    fn = {},
    vars = {},
}

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

lua_party.fn.require("backend/pck.lua")

pck.package_check()
pck.check_version()