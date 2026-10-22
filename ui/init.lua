if lje.state.client then
    hook.pre("lje-util/postrender", "myscript_occ", function()
        if not lua_party.fn.can_render() then return end
        occ.render()
    end)
end

lje.vm.add_pre_engine_call_hook(function(func, nargs, nresults, name)
    if name == "DrawOverlay" and not lje.state.client then
        occ.render()
    end
end, lje.state.menu)

occ.tag = "lua-party " .. lje.script.info().version

occ.sentences = {
    "shoutout for rva",
    "thx jason",
    "thix seven",
    "hey claude how do i un-cuck myself"
}

lua_party.fn.require("ui/menu.lua")