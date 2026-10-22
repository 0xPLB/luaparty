---> themes.lua
-- saves and loads occ.style

lua_party.themes = {}

local TAG = "lua party | themes"
local store = lua_party.configs.store("luaparty-theme-", "theme")

lua_party.themes.list = store.list
lua_party.themes.exists = store.exists
lua_party.themes.new_name = store.new_name
lua_party.themes.delete = store.delete

lua_party.theme_anims = lua_party.theme_anims or {}

lua_party.themes.syncs = {}

local function is_color(v)
    return type(v) == "table" and type(v[1]) == "number"
end

function lua_party.themes.walk(fn)
    for name, section in pairs(occ.style) do
        if is_color(section) or type(section) == "number" then
            fn(name, section, occ.style, name)
        elseif type(section) == "table" then
            for key, value in pairs(section) do
                if is_color(value) or type(value) == "number" then
                    fn(name .. "." .. key, value, section, key)
                end
            end
        end
    end
end

local function snapshot()
    local values, anims = {}, {}

    lua_party.themes.walk(function(path, value)
        values[path] = is_color(value) and {value[1], value[2], value[3], value[4] or 255} or value
        anims[path] = lua_party.theme_anims[path]
    end)

    return {version = 1, values = values, anims = anims}
end

function lua_party.themes.save(name)
    local ok, err = store.write(name, snapshot())
    if not ok then return false, err end

    lua_party.fn.info("saved theme " .. name, TAG)
    return true
end

function lua_party.themes.load(name)
    local data, err = store.read(name)
    if not data then return false, err end
    if type(data.values) ~= "table" then return false, "theme " .. name .. " is broken" end

    local anims = type(data.anims) == "table" and data.anims or {}

    lua_party.themes.walk(function(path, value, parent, key)
        local saved = data.values[path]

        if is_color(value) and is_color(saved) then
            for i = 1, 4 do
                local n = tonumber(saved[i]) or value[i] or 255
                value[i] = math.min(math.max(math.floor(n + 0.5), 0), 255)
            end
        elseif type(value) == "number" and type(saved) == "number" then
            parent[key] = saved
        end

        if is_color(value) then
            lua_party.theme_anims[path] = lua_party.configs.check_anim(anims[path])
        end
    end)

    for _, fn in ipairs(lua_party.themes.syncs) do
        local ok, sync_err = pcall(fn)
        if not ok then lua_party.fn.err("theme widget sync failed: " .. tostring(sync_err), TAG) end
    end

    lua_party.fn.info("loaded theme " .. name, TAG)
    return true
end
