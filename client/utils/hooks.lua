
-- see render_guard.lua: skip a frame rather than draw from inside a model draw
hook.pre("lje-util/render", "luaparty/OnRender2D", function()
    if not lua_party.fn.can_render() then return end
    lua_party.module_manager:Dispatch("OnRender2D")
end)

hook.pre("lje-util/render", "luaparty/OnRender3D", function()
    if not lua_party.fn.can_render() then return end
    cam.Start3D()
        lua_party.module_manager:Dispatch("OnRender3D")
    cam.End()
end)

hook.pre("CalcView", "luaparty/OnCalcView", function(ply, pos, angles, fov)
    lua_party.module_manager:Dispatch("OnCalcView", ply, pos, angles, fov)
end)

hook.pre("Think", "luaparty/OnThink", function()
    lua_party.module_manager:Dispatch("OnThink")
end)

hook.pre("CreateMove", "luaparty/OnCreateMove", function(cmd)
    lua_party.module_manager:Dispatch("OnCreateMove", cmd)
end)

hook.pre("Shutdown", "luaparty/OnShutdown", function()
    lua_party.module_manager:Dispatch("OnShutdown")
end)

gameevent.Listen("player_hurt")
hook.pre("player_hurt", "luaparty/OnPlayerHurt", function(data)
    lua_party.module_manager:Dispatch("OnPlayerHurt", data)
end)

gameevent.Listen("entity_killed")
hook.pre("entity_killed", "luaparty/OnEntityDeath", function(data)
    lua_party.module_manager:Dispatch("OnEntityDeath", data)
end)
