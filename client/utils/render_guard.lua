---> render_guard.lua
-- tells our render hooks whether it's safe to draw right now.
--[[
    lje-util runs "lje-util/render" and "lje-util/postrender" from a post engine
    call hook that fires after the first engine -> lua call to finish once
    PostRender has started, not necessarily after PostRender itself. normally
    that is PostRender. but when a server addon calls render.Capture inside
    PostRender the material system replays the queued
    model draws right there, a lua material proxy (PlayerColor) runs for a player
    model, and when that call ends lje-util runs our render hooks in the middle
    of studiorender drawing that model. calling DrawModel from there clears
    studiorender's current draw state under the outer draw and the game crashes
]]

local last_event = nil

lje.vm.add_pre_engine_call_hook(function(func, nargs, nresults, event)
    last_event = event
end)

function lua_party.fn.can_render()
    return last_event == "PostRender"
end
