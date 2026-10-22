---> pck.lua
-- a update manager for luaparty
pck = {}
pck.http_works = false
pck.dir = lje.env.current_script_path():match("^(.*[\\/])")

-- required lua stuff
local required = {
    "ffi", "occ"
}

local REMOTE_INFO_URL = "https://raw.githubusercontent.com/0xPLB/luaparty/refs/heads/main/info.toml"


---> checks if user has a working HTTP replacement
function pck.check_http() 
    if http.lhttp then
        lua_party.fn.info("pck ok!", "lua party | pck")
        pck.http_works = true
    else
        lua_party.fn.err("lhttp not found in http, do you have lje-http?", "lua party | pck")
    end
end

---> does a dependency check
function pck.package_check()
    local missing = {}

    for _, name in ipairs(required) do
        if _G[name] == nil then
            lua_party.fn.err(string.format("missing: %s", name), "lua party | pck")
            missing[#missing + 1] = "- " .. name
        end
    end

    if #missing == 0 then return end

    local msg = "missing binary modules:\n"
        .. table.concat(missing, "\n")
        .. "\nPlease download them and put them into the binaries folder!"

    utils.message_box(msg, "lua-party | missing dependencies", utils.MB.ICONERROR)
end


---> checks lua-party version
function pck.check_version()
    local localv = lje.script.info().version

    pck.check_http()
    if pck.http_works == false then return end

    http.get(REMOTE_INFO_URL, nil, function(res)
        if res.status ~= 200 then
            lua_party.fn.warn(string.format("version check failed (HTTP %d)", res.status), "lua party | pck")
            return
        end

        local remotev = res.body:match('version%s*=%s*"([^"]+)"')

        local r, l = {}, {}
        for n in remotev:gmatch("%d+") do r[#r + 1] = tonumber(n) end
        for n in localv:gmatch("%d+") do l[#l + 1] = tonumber(n) end

        local newer = false
        for i = 1, math.max(#r, #l) do
            local a, b = r[i] or 0, l[i] or 0
            if a ~= b then
                newer = a > b
                break
            end
        end

        if newer then
            lua_party.fn.warn(string.format("update available: %s -> %s", localv, remotev), "lua party | pck")
            local choice = utils.message_box(
                string.format("A new version of lua-party is available!\n\nyours: %s\nlatest: %s\n\nDo you want to update?", localv, remotev),
                "lua-party | update available",
                bit.bor(utils.MB.YESNO, utils.MB.ICONQUESTION)
            )

            if choice == 6 then
                pck.fetch_repo()
            else
                lua_party.fn.warn("update declined", "lua party | pck")
            end
        else
            lua_party.fn.info(string.format("up to date (%s)", localv), "lua party | pck")
        end
    end, function(res)
        lua_party.fn.warn("version check failed: " .. tostring(res.error), "lua party | pck")
    end)
end

---> fetches the entire repository, replaces files.
function pck.fetch_repo()
    local kernel32 = ffi.module.find("kernel32.dll")
    local CreateFileA = ffi.module.bind_export(kernel32, "CreateFileA", "psuupuup")
    local WriteFile = ffi.module.bind_export(kernel32, "WriteFile", "ipsupp")
    local CloseHandle = ffi.module.bind_export(kernel32, "CloseHandle", "ip")
    local CreateDirectoryA = ffi.module.bind_export(kernel32, "CreateDirectoryA", "isp")

    http.get("https://api.github.com/repos/0xPLB/luaparty/git/trees/main?recursive=1", { ["User-Agent"] = "lua-party" }, function(res)
        if res.status ~= 200 then
            lua_party.fn.err(string.format("couldn't list repo files (HTTP %d)", res.status), "lua party | pck")
            return
        end

        local files = {}
        for path, kind in res.body:gmatch('"path":"([^"]+)","mode":"[^"]*","type":"(%a+)"') do
            if kind == "tree" then
                CreateDirectoryA(pck.dir .. path, nil)
            else
                files[#files + 1] = path
            end
        end

        local remaining, failed = #files, 0

        for _, path in ipairs(files) do
            http.get("https://raw.githubusercontent.com/0xPLB/luaparty/refs/heads/main/" .. path, nil, function(file)
                if file.status == 200 then
                    local handle = CreateFileA(pck.dir .. path, 0x40000000, 0, nil, 2, 0x80, nil)
                    local written = ffi.mem.alloc(4)
                    WriteFile(handle, file.body, #file.body, written, nil)
                    ffi.mem.free(written)
                    CloseHandle(handle)
                    lua_party.fn.info("updated " .. path, "lua party | pck")
                else
                    failed = failed + 1
                    lua_party.fn.err(string.format("failed to fetch %s (HTTP %d)", path, file.status), "lua party | pck")
                end

                remaining = remaining - 1
                if remaining == 0 then
                    utils.message_box(
                        string.format("lua-party updated!\n\n%d files fetched, %d failed.\nReload garry's mod to apply the update.", #files - failed, failed),
                        "lua-party | update",
                        failed == 0 and utils.MB.ICONINFO or utils.MB.ICONWARNING
                    )
                end
            end)
        end
    end)
end