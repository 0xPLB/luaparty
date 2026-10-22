---> esp.lua
-- a wallhack.

local esp = lua_party.module_manager:Register(MODULE:New({
    name = "ESP",
    description = "Basic bounding boxes around players",
    category = "Visuals",
    subcategory = "ESP",
    tag = "Players",
    risk = "UNKNOWN",
    enabled = false,
    can_disable = true,
}))

esp:config({
    { type = "checkbox", name = "Box", default = false },
    { type = "checkbox", name = "Health", default = false },
    { type = "checkbox", name = "Held item", default = false },
    { type = "checkbox", name = "Name", default = false },
    { type = "checkbox", name = "Rank", default = false }
})
local white = {r = 255, g = 255, b = 255, a = 255}
local black = {r = 0, g = 0, b = 0, a = 255}

function esp:OnRender2D()
    lje.util.iterate_players(function(ply)
        if not ply:Alive() or ply:IsDormant() then return end

        local pos = ply:GetPos()
        local top = (pos + Vector(0, 0, ply:OBBMaxs().z)):ToScreen()
        local bottom = pos:ToScreen()
        if not top.visible or not bottom.visible then return end

        local h = bottom.y - top.y
        local w = h / 2
        local x = top.x - w / 2
        local y = top.y

        if self:get("Box") then
            surface.SetDrawColor(0, 0, 0)
            surface.DrawOutlinedRect(x - 1, y - 1, w + 2, h + 2)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawOutlinedRect(x, y, w, h)
        end

        if self:get("Health") then
            local frac = math.Clamp(ply:Health() / ply:GetMaxHealth(), 0, 1)
            surface.SetDrawColor(0, 0, 0)
            surface.DrawRect(x - 6, y - 1, 4, h + 2)
            surface.SetDrawColor(255 * (1 - frac), 255 * frac, 0)
            surface.DrawRect(x - 5, y + h * (1 - frac), 2, h * frac)
        end

        local text_y = y - 2

        if self:get("Name") then
            draw.SimpleTextOutlined(ply:Nick(), "DermaDefault", top.x, text_y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, black)
            text_y = text_y - 12
        end

        if self:get("Rank") then
            draw.SimpleTextOutlined(team.GetName(ply:Team()), "DermaDefault", top.x, text_y, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, black)
        end

        local weapon = ply:GetActiveWeapon()
        if self:get("Held item") and IsValid(weapon) then
            draw.SimpleTextOutlined(weapon:GetClass(), "DermaDefault", top.x, y + h + 2, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, black)
        end
    end)
end
