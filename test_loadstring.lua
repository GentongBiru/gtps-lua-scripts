-- test_loadstring.lua
-- PROBE: apakah engine ini mengizinkan compile + run kode Lua dari string?
-- Ini fondasi remote loader (fetch dari GitHub -> loadstring -> run).
--
-- Cara pakai:
--   1. Copy file ini ke folder script server.
--   2. Reload script server (/rs atau restart).
--   3. Baca server log, cari baris "[probe]".
--
-- Kalau hasilnya "SEMUA LANGKAH LOLOS", lanjut ke test_github_fetch.lua.

local function log(msg)
    print("[probe] " .. msg)
end

-- Baca global pakai rawget supaya TIDAK memicu trap "unknown global".
-- (Kalau sandbox nge-trap akses global tak dikenal, baca langsung bisa
-- meng-abort script ini; rawget bypass metamethod __index.)
local function getGlobal(name)
    local ok, v = pcall(rawget, _G, name)
    if ok then return v end
    return nil
end

log("mulai probe...")

-- LANGKAH 1: ada fungsi compile?
local compile = getGlobal("loadstring") or getGlobal("load")
if type(compile) ~= "function" then
    log("HASIL: loadstring/load TIDAK ADA -> remote loader TIDAK BISA jalan di engine ini.")
    log("probe selesai.")
    return
end
local compileName = getGlobal("loadstring") and "loadstring" or "load"
log("langkah 1 OK: fungsi compile ada (" .. compileName .. ")")

-- LANGKAH 2: bisa compile string jadi chunk?
local chunk, err = compile("return 40 + 2", "@probe")
if not chunk then
    log("HASIL: compile GAGAL: " .. tostring(err))
    log("probe selesai.")
    return
end
log("langkah 2 OK: compile string berhasil")

-- LANGKAH 3: chunk-nya bisa dieksekusi?
local ok, result = pcall(chunk)
if not ok then
    log("HASIL: eksekusi GAGAL: " .. tostring(result))
    log("probe selesai.")
    return
end
log("langkah 3 OK: eksekusi berhasil, hasil = " .. tostring(result) .. " (harusnya 42)")

-- LANGKAH 4: chunk hasil compile bisa akses global engine?
-- (Penting: modul remote harus bisa manggil onPlayerCommandCallback dkk.)
local chunk2 = compile("return getServerName()", "@probe2")
if chunk2 then
    local ok2, res2 = pcall(chunk2)
    if ok2 then
        log("langkah 4 OK: chunk bisa akses getServerName() -> " .. tostring(res2))
    else
        log("HASIL: chunk jalan tapi GAGAL akses global engine: " .. tostring(res2))
        log("probe selesai.")
        return
    end
else
    log("HASIL: compile langkah 4 gagal (tidak terduga)")
    log("probe selesai.")
    return
end

log("HASIL: SEMUA LANGKAH LOLOS -> remote loader BISA jalan di engine ini.")
log("Langkah berikut: taruh test_github_fetch.lua di folder script & reload lagi.")
log("probe selesai.")
