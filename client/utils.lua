utils = {}

function utils.is_state_client()
    if lje.state.client then
        return true
    else
        return false
    end
end

-- MessageBoxA flags
utils.MB = {
    OK = 0x0,
    OKCANCEL = 0x1,
    YESNO = 0x4,
    ICONERROR = 0x10,
    ICONQUESTION = 0x20,
    ICONWARNING = 0x30,
    ICONINFO = 0x40,
}

local message_box_a

-- returns the button id that was pressed 
-- (1 = OK, 2 = Cancel, 6 = Yes, 7 = No)
function utils.message_box(text, title, flags)
    if not message_box_a then
        local user32 = ffi.module.load("user32.dll")
        if not user32 then return nil end

        -- int MessageBoxA(HWND hWnd, LPCSTR text, LPCSTR caption, UINT type)
        message_box_a = ffi.module.bind_export(user32, "MessageBoxA", "ipssi")
        if not message_box_a then return nil end
    end

    return message_box_a(nil, tostring(text), title or "lua-party", flags or utils.MB.OK)
end

