-- loader.lua
-- REMOTE LUA LOADER: fetch modul .lua dari GitHub raw, compile, jalankan.
--
-- Cara pakai:
--   1. Isi CONFIG di bawah (username/repo, ref, daftar modul).
--   2. Copy file ini ke folder script server, reload.
--   3. Tiap modul di-fetch via http.request; callback-nya jalan di tick
--      berikutnya setelah response datang, lalu modul di-compile & run.
--   4. Perintah /rremote (role 998+) untuk fetch ulang semua modul tanpa
--      reload seluruh script server.
--
-- Catatan:
--   - URL harus https LANGSUNG tanpa redirect -> pakai raw.githubusercontent.com.
--   - Maks 512 KB per file (limit response body engine).
--   - Modul remote jalan di environment global yang sama: bisa langsung
--     manggil onPlayerCommandCallback, registerLuaCommand, dll.
--   - Fetch bersifat async: urutan registrasi callback = urutan response
--     datang, BUKAN urutan di CONFIG.modules. Jangan andalkan urutan antar modul.
--   - Untuk produksi, pin ref ke commit SHA / tag, bukan branch main.

local CONFIG = {
    base = "https://raw.githubusercontent.com/USERNAME/REPO/", -- GANTI
    ref  = "main", -- branch / tag / commit SHA. Produksi: pin ke SHA/tag!
    modules = {
        -- "namamodul",   -- akan fetch: base .. ref .. "/namamodul.lua"
    },
}

local TAG = "[loader]"

local function log(msg)
    print(TAG .. " " .. msg)
end

-- Baca global pakai rawget agar tidak memicu trap "unknown global".
local function getGlobal(name)
    local ok, v = pcall(rawget, _G, name)
    if ok then return v end
    return nil
end

local compile = getGlobal("loadstring") or getGlobal("load")
if type(compile) ~= "function" then
    log("loadstring/load tidak tersedia di engine ini — remote loading dimatikan.")
    log("Jalankan test_loadstring.lua untuk konfirmasi.")
    return
end

local function fetchModule(name)
    local url = CONFIG.base .. CONFIG.ref .. "/" .. name .. ".lua"
    log("fetch " .. name .. " <- " .. url)
    http.request({
        url = url,
        method = "GET",
        callback = function(res)
            if not res.ok then
                log(name .. ": request gagal (" .. tostring(res.error) .. ")")
                return
            end
            if res.status ~= 200 then
                log(name .. ": HTTP " .. tostring(res.status) .. " — cek nama file / ref.")
                return
            end
            local chunk, err = compile(res.body, "@" .. name)
            if not chunk then
                log(name .. ": COMPILE ERROR: " .. tostring(err))
                return
            end
            local ok, rerr = pcall(chunk)
            if not ok then
                log(name .. ": RUNTIME ERROR: " .. tostring(rerr))
            else
                log(name .. ": OK (" .. #res.body .. " bytes)")
            end
        end,
    })
end

local function fetchAll()
    if #CONFIG.modules == 0 then
        log("tidak ada modul terdaftar — isi CONFIG.modules dulu.")
        return
    end
    for _, name in ipairs(CONFIG.modules) do
        fetchModule(name)
    end
end

-- Perintah /rremote: fetch ulang semua modul remote (staff+ saja).
registerLuaCommand({
    command = "rremote",
    roleRequired = 998,
    description = "Fetch ulang semua modul Lua remote dari GitHub",
    callback = function(player, args)
        if not player:hasRole(998) then
            player:onConsoleMessage("`4No access.")
            return true
        end
        fetchAll()
        player:onConsoleMessage("`2Fetching ulang modul remote, cek server log...")
        return true
    end,
})

fetchAll()
log("loader siap. /rremote untuk fetch ulang.")
