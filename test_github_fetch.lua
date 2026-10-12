-- test_github_fetch.lua
-- TES JALUR FETCH: http.request -> raw.githubusercontent.com -> compile -> run.
--
-- Cara pakai:
--   1. Pastikan test_loadstring.lua sudah LOLOS (loadstring/load tersedia).
--   2. Copy file ini ke folder script server, reload, baca server log ("[fetchtest]").
--   3. Mode default memakai URL README kecil milik GitHub sendiri: ini mengetes
--      koneksi, aturan no-redirect, status 200, dan body yang kebaca.
--   4. Untuk tes END-TO-END penuh: buat file .lua kecil di repomu
--      (misal isinya:  print("[remotefetch] halo dari github!")  ),
--      ganti CONFIG.url ke raw URL file itu, set expect_lua = true, reload.

local TAG = "[fetchtest]"

local CONFIG = {
    url = "https://raw.githubusercontent.com/octocat/Hello-World/master/README",
    expect_lua = false, -- set true kalau url mengarah ke file .lua valid
}

local function log(msg)
    print(TAG .. " " .. msg)
end

local function getGlobal(name)
    local ok, v = pcall(rawget, _G, name)
    if ok then return v end
    return nil
end

local compile = getGlobal("loadstring") or getGlobal("load")
if type(compile) ~= "function" then
    log("loadstring/load tidak ada — jalankan test_loadstring.lua dulu.")
    return
end

log("fetch " .. CONFIG.url .. " ...")

http.request({
    url = CONFIG.url,
    method = "GET",
    callback = function(res)
        if not res.ok then
            log("HASIL: request gagal total: " .. tostring(res.error))
            log("Kemungkinan: server tidak punya akses internet keluar / host diblokir.")
            return
        end

        log("HTTP status = " .. tostring(res.status))
        if res.status ~= 200 then
            log("HASIL: status bukan 200 — cek URL-nya.")
            log("Ingat: engine TIDAK mengizinkan redirect, pakai raw.githubusercontent.com langsung.")
            return
        end

        local body = res.body or ""
        local preview = body:sub(1, 60):gsub("\n", " ")
        log("body terbaca: " .. #body .. " bytes. 60 char pertama: [" .. preview .. "]")

        if CONFIG.expect_lua then
            -- END-TO-END: compile langsung body yang di-fetch dari GitHub.
            local chunk, err = compile(body, "@remotefetch")
            if not chunk then
                log("HASIL: body ter-fetch tapi COMPILE GAGAL: " .. tostring(err))
                return
            end
            local ok, rerr = pcall(chunk)
            if ok then
                log("HASIL: END-TO-END LOLOS! Script dari GitHub ter-fetch, ter-compile, & jalan.")
            else
                log("HASIL: compile OK tapi RUNTIME ERROR: " .. tostring(rerr))
            end
            return
        end

        -- Mode default: body-nya README (bukan Lua), jadi verifikasi compile
        -- memakai snippet lokal — yang penting jalur HTTP-nya terbukti OK.
        local chunk2, err2 = compile("return 'compile-path OK'", "@fetchtest")
        if chunk2 then
            local ok2, r2 = pcall(chunk2)
            log("compile+run snippet lokal OK: " .. tostring(r2))
        else
            log("compile snippet lokal GAGAL: " .. tostring(err2))
            return
        end

        log("HASIL: jalur HTTP OK + compile OK -> remote loader BISA jalan.")
        log("Untuk end-to-end penuh: ganti CONFIG.url ke file .lua di repomu & set expect_lua = true.")
    end,
})
