# Neovim Config (Termux / Android)

Konfigurasi Neovim ringan tapi feature-complete untuk Termux di Android
(Neovim 0.12+, API lazy.nvim). Cocok dipakai bareng Hermes Agent.

## Fitur

- **Auto-reload buffer** — kalau file diubah dari luar nvim (mis. Hermes
  edit file di terminal), cukup gerak cursor / pindah buffer / balik focus,
  isinya langsung ke-reload tanpa keluar nvim.
- **Picker tema** — `<leader>cs` membuka Telescope colorscheme picker.
  Default tema: **tokyonight-night** (alternatif: catppuccin-mocha, dll).
- **Syntax highlight banyak bahasa** — Treesitter aktif untuk ~26 bahasa
  (lua, python, javascript, typescript, html, css, bash, json, yaml,
  markdown, c/cpp, go, rust, java, php, ruby, dll). Parser otomatis
  ter-install saat pertama buka.
- **Auto-format saat simpan** — `<leader>w` / `:w` memanggil
  `vim.lsp.buf.format` (pakai LSP: pyright, html, cssls, ts_ls).
- **Plugin lain** — lualine, nvim-tree, telescope, nvim-autopairs,
  Comment.nvim, which-key, bufferline, indent-blankline, gitsigns,
  toggleterm, nvim-cmp + LuaSnip, mason + LSP.

## Keymap penting

| Tombol | Fungsi |
|--------|--------|
| `<leader>w` | Save |
| `<leader>q` | Quit |
| `<leader>cs` | Pilih tema (colorscheme) |
| `<leader>ff` | Find files (Telescope) |
| `<leader>fg` | Live grep (Telescope) |
| `<leader>e` | Toggle file explorer |
| `<C-\>` | Toggle terminal (toggleterm) |
| `<leader>sv` / `<leader>sh` | Split vertikal / horizontal |

## Install

### 1. Dependencies (Termux) — WAJIB di-install dulu

```bash
pkg update
pkg install -y neovim git nodejs npm ripgrep clang lua-language-server python python-pip
npm install -g typescript@5.6.3
```

Penjelasan:
- `neovim`            → editor utama
- `git`               → lazy.nvim clone plugin dari GitHub
- `nodejs` + `npm`    → butuh ts_ls (JS/TS LSP) & beberapa LSP Mason berbasis node
- `ripgrep`           → Telescope live_grep (`:leader fg`) butuh ini
- `clang`             → compiler C untuk build parser Treesitter (wajib)
- `lua-language-server` → binary system untuk lua_ls (sesuai config)
- `python` + `python-pip` → Mason install pyright (LSP Python) lewat pip internal
- `npm -g typescript@5.6.3` → ts_ls diarahkan ke versi ini (7.x broken di android-arm64)

Yang di-handle otomatis (TIDAK perlu install manual):
- lazy.nvim → clone otomatis saat nvim pertama kali buka
- Semua plugin → install otomatis lewat `:Lazy sync`
- Parser Treesitter → auto-install saat VimEnter (butuh clang di atas)
- LSP (pyright, html, cssls) → di-install Mason otomatis saat `:Lazy sync`

### 2. Clone & sync

```bash
# Backup config lama kalau ada
mv ~/.config/nvim ~/.config/nvim.bak 2>/dev/null

# Clone repo ini
git clone https://github.com/rmt26/nvim-config.git ~/.config/nvim

# Buka nvim, lalu install plugin:
:Lazy sync
```

Setelah `:Lazy sync` selesai, restart nvim. Tema tokyonight-night dan
Treesitter parser akan aktif otomatis.

Catatan pip: user TIDAK perlu jalanin pip manual. Mason memanggil pip sendiri
saat install pyright (pastikan `python` + `python-pip` sudah terpasang di Termux).

## Catatan Termux

UNTUK PENGGUNA TERMUX (Android): tidak perlu mengubah init.lua sama sekali.
Cukup install dependency di bawah ini, lalu clone & :Lazy sync.

  pkg install lua-language-server
  npm install -g typescript@5.6.3

Penjelasan bagian khusus Termux di dalam init.lua:
- `lua_ls` memakai binary system `lua-language-server` (bukan build Mason
  yang gagal di Termux).
- `ts_ls` diarahkan ke typescript global 5.6.3 karena ts 7.x broken di
  android-arm64.

UNTUK PENGGUNA SELAIN TERMUX (Linux desktop, macOS, WSL):
mungkin perlu mengedit init.lua jika path/nama binary atau versi berbeda
di environment kamu, misalnya pakai lua_ls via Mason atau ts_ls versi
terbaru. Sesuaikan bagian `vim.lsp.config(...)` sesuai environment masing-masing.
