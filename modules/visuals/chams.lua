---> chams.lua
-- flat coloured player models through walls.

local chams = lua_party.module_manager:Register(MODULE:New({
    name = "Chams",
    description = "Draws players in a flat colour through walls",
    category = "Visuals",
    subcategory = "Chams",
    tag = "Players",
    risk = "UNKNOWN",
    enabled = false,
    can_disable = true,
}))

chams:config({
    { type = "colorpicker", name = "Color", default = {255, 0, 255, 255} },
})

function chams:OnRender3D()
    -- made in main.lua
    local material = lua_party.materials.basic
    if not material then return end

    local color = self:get("Color")

    render.SuppressEngineLighting(true)
    render.MaterialOverride(material)
    render.SetColorModulation(color[1] / 255, color[2] / 255, color[3] / 255)
    render.SetBlend(color[4] / 255)

    -- pcall so an error can't leave the override on for every model next frame
    local ok, err = pcall(lje.util.iterate_players, function(ply)
        if ply:Alive() and not ply:IsDormant() then
            ply:DrawModel()
        end
    end)

    render.SetBlend(1)
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride()
    render.SuppressEngineLighting(false)

    if not ok then error(err, 0) end
end
