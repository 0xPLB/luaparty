---> configs.lua
-- saves and loads every module's enabled state and settings.

lua_party.configs = {}

local TAG = "lua party | configs"

local encode

local function encode_string(s)
    return '"' .. s:gsub('[%c"\\]', function(c)
        if c == '"' then return '\\"' end
        if c == "\\" then return "\\\\" end
        if c == "\n" then return "\\n" end
        if c == "\t" then return "\\t" end
        return string.format("\\u%04x", c:byte())
    end) .. '"'
end

local function is_list(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    for i = 1, n do
        if t[i] == nil then return false end
    end
    return true
end

function encode(value)
    local kind = type(value)

    if kind == "string" then return encode_string(value) end
    if kind == "boolean" then return tostring(value) end

    if kind == "number" then
        -- nan and inf have no json form
        if value ~= value or value == math.huge or value == -math.huge then return "0" end
        if value == math.floor(value) then return string.format("%d", value) end
        return string.format("%.17g", value)
    end

    if kind == "table" then
        local out = {}

        if is_list(value) then
            for i, v in ipairs(value) do out[i] = encode(v) end
            return "[" .. table.concat(out, ",") .. "]"
        end

        local keys = {}
        for k in pairs(value) do keys[#keys + 1] = tostring(k) end
        table.sort(keys)

        for _, k in ipairs(keys) do
            out[#out + 1] = encode_string(k) .. ":" .. encode(value[k])
        end
        return "{" .. table.concat(out, ",") .. "}"
    end

    return "null"
end

local function decode(str)
    local pos = 1

    local function fail(msg)
        error(string.format("bad config json at %d: %s", pos, msg), 0)
    end

    local function skip()
        pos = str:find("[^ \t\r\n]", pos) or #str + 1
    end

    local value

    local function read_string()
        pos = pos + 1
        local out = {}

        while true do
            local c = str:sub(pos, pos)

            if c == "" then fail("unterminated string") end

            if c == '"' then
                pos = pos + 1
                return table.concat(out)
            end

            if c == "\\" then
                local e = str:sub(pos + 1, pos + 1)

                if e == "u" then
                    local code = tonumber(str:sub(pos + 2, pos + 5), 16) or fail("bad \\u escape")
                    out[#out + 1] = code < 256 and string.char(code) or "?"
                    pos = pos + 6
                else
                    local map = {n = "\n", t = "\t", r = "\r", b = "\b", f = "\f", ['"'] = '"', ["\\"] = "\\", ["/"] = "/"}
                    out[#out + 1] = map[e] or fail("bad escape")
                    pos = pos + 2
                end
            else
                out[#out + 1] = c
                pos = pos + 1
            end
        end
    end

    function value()
        skip()
        local c = str:sub(pos, pos)

        if c == "{" then
            local out = {}
            pos = pos + 1
            skip()
            if str:sub(pos, pos) == "}" then pos = pos + 1 return out end

            while true do
                skip()
                if str:sub(pos, pos) ~= '"' then fail("expected key") end
                local k = read_string()
                skip()
                if str:sub(pos, pos) ~= ":" then fail("expected ':'") end
                pos = pos + 1
                out[k] = value()
                skip()
                local d = str:sub(pos, pos)
                pos = pos + 1
                if d == "}" then return out end
                if d ~= "," then fail("expected ',' or '}'") end
            end
        end

        if c == "[" then
            local out = {}
            pos = pos + 1
            skip()
            if str:sub(pos, pos) == "]" then pos = pos + 1 return out end

            while true do
                out[#out + 1] = value()
                skip()
                local d = str:sub(pos, pos)
                pos = pos + 1
                if d == "]" then return out end
                if d ~= "," then fail("expected ',' or ']'") end
            end
        end

        if c == '"' then return read_string() end

        for word, result in pairs({["true"] = true, ["false"] = false}) do
            if str:sub(pos, pos + #word - 1) == word then
                pos = pos + #word
                return result
            end
        end

        if str:sub(pos, pos + 3) == "null" then
            pos = pos + 4
            return nil
        end

        local num = str:match("^-?%d+%.?%d*[eE]?[-+]?%d*", pos)
        if num and num ~= "" and tonumber(num) then
            pos = pos + #num
            return tonumber(num)
        end

        fail("unexpected '" .. c .. "'")
    end

    local ok, result = pcall(value)
    if not ok then return nil, result end
    return result
end

lua_party.configs.encode = encode
lua_party.configs.decode = decode

local function valid_name(name)
    return type(name) == "string" and #name > 0 and #name <= 100
        and name ~= "index" -- that one is the index itself?
        and name:match("^[%w_%-]+$") ~= nil
end

function lua_party.configs.store(prefix, kind)
    local store = {}
    local index = prefix .. "index"

    function store.list()
        local names = {}

        for line in (lje.data.read(index) or ""):gmatch("[^\r\n]+") do
            if valid_name(line) then names[#names + 1] = line end
        end

        return names
    end

    local function write_index(names)
        return lje.data.write(index, table.concat(names, "\n"))
    end

    function store.exists(name)
        return utils.in_enum(store.list(), name)
    end

    function store.new_name()
        local i = 1
        while store.exists(kind .. "-" .. i) do i = i + 1 end
        return kind .. "-" .. i
    end

    function store.write(name, data)
        if not valid_name(name) then
            return false, kind .. " names can only use letters, digits, _ and -"
        end

        if not lje.data.write(prefix .. name, encode(data)) then
            return false, "could not write " .. name
        end

        local names = store.list()
        if not utils.in_enum(names, name) then
            names[#names + 1] = name
            write_index(names)
        end

        return true
    end

    function store.read(name)
        if not valid_name(name) then return nil, "bad " .. kind .. " name" end

        local raw = lje.data.read(prefix .. name)
        if not raw or raw == "" then return nil, kind .. " " .. name .. " not found" end

        local data, err = decode(raw)
        if type(data) ~= "table" then
            return nil, err or kind .. " " .. name .. " is broken"
        end

        return data
    end

    function store.delete(name)
        local names = store.list()

        for i = #names, 1, -1 do
            if names[i] == name then table.remove(names, i) end
        end

        write_index(names)
        -- lje.data can't delete, so the entry is emptied and left out of the index
        if valid_name(name) then lje.data.write(prefix .. name, "") end

        return true
    end

    return store
end

local store = lua_party.configs.store("luaparty-cfg-", "config")

lua_party.configs.list = store.list
lua_party.configs.exists = store.exists
lua_party.configs.new_name = store.new_name
lua_party.configs.delete = store.delete

---> save / load

local function deep_copy(t)
    local out = {}
    for k, v in pairs(t) do
        out[k] = type(v) == "table" and deep_copy(v) or v
    end
    return out
end

-- every module's state, as it is right now
local function snapshot()
    local modules = {}

    for _, module in ipairs(lua_party.module_manager:GetAll()) do
        modules[module.name] = {
            enabled = module.enabled,
            settings = deep_copy(module.settings),
        }
    end

    return {version = 1, modules = modules}
end

-- the value to store for a setting, or nil if the saved one doesn't fit it
local function check(entry, current, saved)
    if type(saved) ~= type(current) then return nil end

    if entry.type == "dropdown" and entry.options then
        if entry.multiple then
            local out = {}
            for _, option in ipairs(saved) do
                if utils.in_enum(entry.options, option) then out[#out + 1] = option end
            end
            return out
        end

        return utils.in_enum(entry.options, saved) and saved or nil
    end

    if entry.type == "slider" and type(saved) == "number" then
        return math.min(math.max(saved, entry.min or saved), entry.max or saved)
    end

    if entry.type == "colorpicker" then
        local out = {}
        for i = 1, 4 do
            local n = tonumber(saved[i]) or 255
            out[i] = math.min(math.max(math.floor(n + 0.5), 0), 255)
        end
        return out
    end

    return saved
end

local ANIMATIONS = {rainbow = true, pulse = true}

-- a colorpicker's saved animation, or nil if there is none or it's junk
local function check_anim(saved)
    if type(saved) ~= "table" or not ANIMATIONS[saved.mode] then return nil end
    if type(saved.base) ~= "table" then return nil end

    local function clamp(n, lo, hi)
        n = tonumber(n)
        if not n then return nil end
        return math.min(math.max(n, lo), hi)
    end

    local h, s, v, a = clamp(saved.base[1], 0, 360), clamp(saved.base[2], 0, 1),
        clamp(saved.base[3], 0, 1), clamp(saved.base[4], 0, 1)
    if not (h and s and v and a) then return nil end

    return {mode = saved.mode, rate = clamp(saved.rate, 0, 5) or 1, base = {h, s, v, a}}
end

lua_party.configs.check_anim = check_anim

function lua_party.configs.save(name)
    local ok, err = store.write(name, snapshot())
    if not ok then return false, err end

    lua_party.fn.info("saved config " .. name, TAG)
    return true
end

function lua_party.configs.load(name)
    local data, err = store.read(name)
    if not data then return false, err end
    if type(data.modules) ~= "table" then return false, "config " .. name .. " is broken" end

    for module_name, saved in pairs(data.modules) do
        local module = lua_party.module_manager:Get(module_name)

        -- modules that were removed since, or junk, are skipped
        if module and type(saved) == "table" then
            if type(saved.settings) == "table" then
                for _, entry in ipairs(module.configs) do
                    local value = check(entry, module.settings[entry.key], saved.settings[entry.key])
                    if value ~= nil then module.settings[entry.key] = value end

                    if entry.type == "colorpicker" then
                        local animkey = lua_party.config.animkey(entry.key)
                        module.settings[animkey] = check_anim(saved.settings[animkey])
                    end
                end
            end

            if saved.enabled == true then
                module:Enable()
            elseif saved.enabled == false then
                module:Disable()
            end
        end
    end

    -- the widgets keep their own state, so bring them in line
    lua_party.config.sync()

    lua_party.fn.info("loaded config " .. name, TAG)
    return true
end
