---> bhop.lua
-- hop like a bunny.

local bhop = lua_party.module_manager:Register(MODULE:New({
    name = "Bhop",
    description = "Hold jump to bunnyhop",
    category = "Movement",
    subcategory = "General",
    risk = "UNKNOWN",
    enabled = false,
    can_disable = true,
}))

function bhop:OnCreateMove(cmd)
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    -- don't mess with jumping on ladders, in noclip or while swimming
    local move_type = ply:GetMoveType()
    if move_type == MOVETYPE_NOCLIP or move_type == MOVETYPE_LADDER then return end
    if ply:WaterLevel() >= 2 then return end

    if cmd:KeyDown(IN_JUMP) and not ply:IsOnGround() then
        cmd:RemoveKey(IN_JUMP)
    end
end
