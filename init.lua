-- ================================
-- Neovim Config untuk Termux (Neovim 0.12 / API baru)
-- ================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Catatan: colorscheme diterapkan dari dalam config plugin tokyonight (lihat bawah),
-- karena saat init.lua dijalankan plugin lazy.nvim belum di-load.

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.wrap = false
opt.breakindent = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.termguicolors = true
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 8
opt.cursorline = true

-- Auto-reload buffer kalau file berubah di luar nvim (mis. Hermes edit file)
-- autoread: reload otomatis kalau buffer belum ada edit lokal
opt.autoread = true
vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "FocusGained" }, {
  callback = function() vim.cmd("checktime") end,
})

-- Auto-format saat simpan (spasi+w / :w / BufWritePre)
-- Memanfaatkan LSP yang ter-attach (pyright, html, cssls, ts_ls, dll).
-- Kalau belum ada LSP yg support formatting, baris ini no-op (aman).
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    vim.lsp.buf.format({ async = true, timeout_ms = 2000 })
  end,
})

local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear highlight" })
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")
map("n", "<leader>sv", "<cmd>vsplit<cr>")
map("n", "<leader>sh", "<cmd>split<cr>")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    -- setup() & colorscheme sudah dipanggil di awal init.lua (lihat atas)
    -- agar theme lualine terdaftar sebelum lualine di-load.
  },

  -- Tema default: tokyonight-night (diterapkan SETELAH plugin di-load oleh lazy)
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    opts = {},
    config = function()
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin/nvim" },
    config = function()
      local function setup_lualine()
        local theme = "tokyonight-night"
        -- Fallback aman kalau module theme belum ke-load
        pcall(function()
          theme = require("lualine.themes.tokyonight-night")
        end)
        require("lualine").setup({ options = { theme = theme } })
      end
      -- Setup sekarang; kalau theme string belum resolve, ulangi saat VimEnter
      setup_lualine()
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = setup_lualine,
      })
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = { width = 30 },
        renderer = { group_empty = true },
      })
      map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Explorer" })
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      map("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      map("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
      map("n", "<leader>fh", builtin.help_tags, { desc = "Help" })
      -- Pilih tema (colorscheme) secara live dari daftar tema yang ter-install
      map("n", "<leader>cs", builtin.colorscheme, { desc = "Pilih tema" })
    end,
  },

  -- nvim-treesitter (rewrite baru): `configs` sudah tidak ada.
  -- Setup cukup tanpa argumen; highlight/indent diaktifkan per FileType.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    config = function()
      -- Daftar bahasa yang di-highlight & parser-nya dijamin ter-install.
      -- Tambahkan sendiri nama bahasa di sini kalau butuh lebih banyak.
      local langs = {
        "lua", "vim", "vimdoc", "python", "javascript",
        "typescript", "tsx", "jsx", "html", "css", "scss",
        "bash", "json", "yaml", "markdown", "markdown_inline",
        "query", "c", "cpp", "go", "rust", "java", "php",
        "ruby", "toml", "dockerfile", "gitignore", "comment",
      }

      require("nvim-treesitter").setup({
        ensure_installed = langs,
        highlight = { enable = true },
        indent = { enable = true },
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = langs,
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          pcall(vim.treesitter.start, buf)
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      -- Bootstrap: kalau ada parser yang belum ter-install, install otomatis.
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          local ok, mod = pcall(require, "nvim-treesitter.config")
          if not ok then return end
          local installed = mod.get_installed()
          local missing = vim.tbl_filter(
            function(l) return not vim.tbl_contains(installed, l) end,
            langs
          )
          if #missing > 0 then
            vim.notify("Treesitter: install parser " .. table.concat(missing, ", "),
              vim.log.levels.INFO)
            pcall(function()
              require("nvim-treesitter.install").install(missing)
            end)
          end
        end,
      })
    end,
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  {
    "numToStr/Comment.nvim",
    config = true,
  },

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup()
    end,
  },

  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup()
      map("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>")
      map("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>")
      map("n", "<leader>x", "<cmd>bdelete<cr>", { desc = "Close buffer" })
    end,
  },

  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = true,
  },

  {
    "lewis6991/gitsigns.nvim",
    config = true,
  },

  -- LSP: pakai API vim.lsp.config / vim.lsp.enable (Neovim 0.11+)
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      require("mason").setup()
      -- lua_ls & ts_ls dikecualikan: butuh penanganan khusus (lihat bawah)
      require("mason-lspconfig").setup({
        ensure_installed = { "pyright", "html", "cssls" },
        automatic_enable = {
          exclude = { "lua_ls", "ts_ls" },
        },
      })

      local cmp = require("cmp")
      local caps = require("cmp_nvim_lsp").default_capabilities()
      local luasnip = require("luasnip")

      -- Load koleksi snippet VSCode-style (menyediakan `fu`, `for`, dll per bahasa)
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Snippet custom `fun` (kebiasaan user) untuk beberapa bahasa
      local ls = require("luasnip")
      local s, i, t, fmt = ls.snippet, ls.insert_node, ls.text_node, require("luasnip.extras.fmt").fmt
      ls.add_snippets("lua", {
        s("fun", fmt([[
function {}({})
  {}
end]], { i(1, "name"), i(2), i(0) })),
      })
      ls.add_snippets("python", {
        s("fun", fmt([[
def {}({}):
    {}]], { i(1, "name"), i(2), i(0, "pass") })),
      })
      ls.add_snippets("javascript", {
        s("fun", fmt([[
function {}({}) {{
  {}
}}]], { i(1, "name"), i(2), i(0) })),
      })
      ls.filetype_extend("typescript", { "javascript" })

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })

      -- Capabilities default untuk semua server
      vim.lsp.config("*", { capabilities = caps })

      -- LSP keymaps via LspAttach (pola modern, tidak perlu on_attach per server)
      local lsp_keymaps = function(buf)
        local opts = { buffer = buf }
        map("n", "gd", vim.lsp.buf.definition, opts)
        map("n", "K", vim.lsp.buf.hover, opts)
        map("n", "<leader>rn", vim.lsp.buf.rename, opts)
        map("n", "<leader>ca", vim.lsp.buf.code_action, opts)
        map("n", "gr", vim.lsp.buf.references, opts)
      end
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          lsp_keymaps(args.buf)
        end,
      })

      -- lua_ls: pakai binary system (3.18.2) karena mason build gagal di Termux
      vim.lsp.config("lua_ls", {
        cmd = { "lua-language-server" },
        capabilities = caps,
      })
      vim.lsp.enable("lua_ls")

      -- ts_ls: arahkan tsserver ke typescript global 5.6.3
      -- (mason bundling ts 6.x broken di android-arm64)
      local npm_global = vim.trim(vim.fn.system("npm root -g"))
      local global_ts = npm_global .. "/typescript"
      vim.lsp.config("ts_ls", {
        capabilities = caps,
        init_options = {
          tsserver = { path = global_ts },
        },
      })
      vim.lsp.enable("ts_ls")
    end,
  },

  -- Terminal terintegrasi (toggleterm)
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<C-\>]],   -- Ctrl-\ : toggle terminal cepat
        direction = "float",
        float_opts = { border = "curved" },
        shade_terminals = true,
        start_in_insert = true,
        persist_size = true,
      })

      local Terminal = require("toggleterm.terminal").Terminal
      local float_term = Terminal:new({ direction = "float", hidden = true })
      local horiz_term = Terminal:new({ direction = "horizontal", hidden = true })
      local vert_term  = Terminal:new({ direction = "vertical", hidden = true })

      -- Normal mode shortcuts (leader = spasi)
      map("n", "<leader>tf", function() float_term:toggle() end, { desc = "Terminal float" })
      map("n", "<leader>th", function() horiz_term:toggle() end, { desc = "Terminal horizontal" })
      map("n", "<leader>tv", function() vert_term:toggle() end,  { desc = "Terminal vertical" })
      map("n", "<leader>tt", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })

      -- Keluar dari mode terminal & navigasi window dari dalam terminal
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*toggleterm#*",
        callback = function()
          local o = { buffer = 0 }
          map("t", "<Esc>", [[<C-\><C-n>]], o)          -- Esc: keluar ke normal mode
          map("t", "<C-h>", [[<Cmd>wincmd h<cr>]], o)
          map("t", "<C-j>", [[<Cmd>wincmd j<cr>]], o)
          map("t", "<C-k>", [[<Cmd>wincmd k<cr>]], o)
          map("t", "<C-l>", [[<Cmd>wincmd l<cr>]], o)
        end,
      })
    end,
  },
}, {
  ui = {
    border = "rounded",
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
