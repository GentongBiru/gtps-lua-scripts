# gtps-lua-scripts

Script Lua buat server GTPS Amba. Dipakai bareng remote loader.

- `test_loadstring.lua` — probe: apakah engine mengizinkan `loadstring`/`load`.
- `test_github_fetch.lua` — tes jalur `http.request` ke raw.githubusercontent.com.
- `loader.lua` — fetch modul `.lua` dari repo ini lalu jalankan. Isi `CONFIG` dulu
  (username/repo, ref, daftar modul), copy ke folder script server.
