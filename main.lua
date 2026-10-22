lje.include("client/loader/init.lua")

lua_party.materials = {
    basic = CreateMaterial(lje.util.random_string(), "UnlitGeneric", {
        ["$basetexture"] = "color/white",
        ["$model"] = 1,
    }),
}
