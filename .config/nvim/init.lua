-- リーダーキーの設定
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 基本設定
vim.opt.number = true           -- 行番号を表示
vim.opt.clipboard = "unnamedplus" -- システムクリップボードを使用
vim.opt.expandtab = true        -- タブをスペースに変換
vim.opt.tabstop = 2             -- タブ幅を2に設定
vim.opt.shiftwidth = 2          -- インデント幅を2に設定

-- ヘルパー関数
local function extract_real_path(path)
  -- fugitiveのパスから実際のファイルパスを抽出
  if path:match("^fugitive://") then
    local real_path = vim.fn.FugitiveReal(path)
    if real_path:match("^fugitive://") then
      real_path = real_path:match("/%.git/.-//%d+/(.*)$") or real_path
    end
    return real_path
  end
  return path
end

local function get_relative_path(path)
  -- 絶対パスの場合は相対パスに変換
  if path:match("^/") then
    return vim.fn.fnamemodify(path, ":.")
  end
  return path
end

local function get_current_file_path()
  local path = vim.fn.expand("%")
  path = extract_real_path(path)
  return get_relative_path(path)
end

-- キーマッピング
vim.keymap.set("i", "jj", "<esc><cmd>w<CR>", { desc = "jjでインサートモードを抜けて保存" })

-- ファイルパス関連
vim.keymap.set("n", "<leader>cp", function()
  local path = get_current_file_path()
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end, { desc = "Copy relative file path" })

-- フルパス（絶対パス）をコピー
vim.keymap.set("n", "<leader>cP", function()
  local path = vim.fn.expand("%:p")
  local real_path = extract_real_path(path) or path
  vim.fn.setreg("+", real_path)
  print("Copied full path: " .. real_path)
end, { desc = "Copy full (absolute) path" })

-- ファイルパスとコード選択範囲をコピー
vim.keymap.set("v", "<leader>cc", function()
  local path = get_current_file_path()

  -- 選択範囲のテキストを取得
  vim.cmd('normal! "vy')
  local selected_text = vim.fn.getreg("v")

  -- フォーマットを作成
  local formatted = "@" .. path .. "\n\n```\n" .. selected_text .. "\n```"

  vim.fn.setreg("+", formatted)
  print("Copied: @" .. path .. " with selected text")
end, { desc = "Copy file path with selected code" })

-- GitHub でファイルを開く
vim.keymap.set("n", "<leader>gh", function()
  local path = get_current_file_path()
  vim.cmd("!gh browse " .. path .. " --commit")
  print("Opening: " .. path .. " in GitHub at current commit")
end, { desc = "Open file in GitHub at current commit" })

-- GitHub でファイルを行番号付きで開く（ビジュアルモード）
vim.keymap.set("v", "<leader>gh", function()
  local path = get_current_file_path()

  -- 選択範囲を取得（ビジュアルモード中に取得）
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")

  -- 開始行と終了行を正しい順序にする
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  -- 行番号が0の場合は現在行を使用
  if start_line == 0 then
    start_line = vim.fn.line(".")
  end

  local line_part
  if start_line == end_line then
    line_part = ":" .. start_line
  else
    line_part = ":" .. start_line .. "-" .. end_line
  end

  vim.cmd("!gh browse " .. path .. line_part .. " --commit")
  if start_line == end_line then
    print("Opening: " .. path .. " line " .. start_line .. " in GitHub at current commit")
  else
    print("Opening: " .. path .. " lines " .. start_line .. "-" .. end_line .. " in GitHub at current commit")
  end
end, { desc = "Open file in GitHub with selected lines at current commit" })

-- Finderでファイルを開く（macOS）
vim.keymap.set("n", "<leader>fo", function()
  local path = vim.fn.expand("%:p")
  local real_path = extract_real_path(path) or path
  if real_path and real_path ~= "" then
    vim.fn.system({ "open", "-R", real_path })
    print("Opened in Finder: " .. real_path)
  else
    print("No file to open")
  end
end, { desc = "Open file in Finder" })

-- 設定再読み込み（lazy.nvim対応）
vim.keymap.set("n", "<leader>r", function()
  vim.cmd("Lazy reload")
  print("Config reloaded!")
end, { desc = "Reload config" })

-- lazy.nvimのセットアップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- プラグインの設定
require("lazy").setup({
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        on_highlights = function(hl, c)
          -- 補完メニューの背景と前景
          hl.Pmenu = { bg = c.bg_popup, fg = c.fg }
          hl.PmenuSel = { bg = c.bg_highlight, fg = c.fg, bold = true }

          -- マッチした文字を目立たせる
          hl.CmpItemAbbrMatch = { fg = c.blue, bold = true }
          hl.CmpItemAbbrMatchFuzzy = { fg = c.blue }

          -- ソース名の表示
          hl.CmpItemMenu = { fg = c.magenta, italic = true }

          -- Copilot提案（TokyoNight緑）
          hl.CmpItemKindCopilot = { fg = c.green }

          -- 関数とメソッド
          hl.CmpItemKindFunction = { fg = c.magenta }
          hl.CmpItemKindMethod = { fg = c.magenta }

          -- 変数とフィールド
          hl.CmpItemKindVariable = { fg = c.cyan }
          hl.CmpItemKindField = { fg = c.cyan }

          -- クラスと型
          hl.CmpItemKindClass = { fg = c.orange }
          hl.CmpItemKindInterface = { fg = c.orange }
          hl.CmpItemKindStruct = { fg = c.orange }

          -- キーワード
          hl.CmpItemKindKeyword = { fg = c.blue }
          hl.CmpItemKindOperator = { fg = c.blue }

          -- 定数
          hl.CmpItemKindConstant = { fg = c.yellow }
          hl.CmpItemKindEnum = { fg = c.yellow }

          -- モジュールとプロパティ
          hl.CmpItemKindModule = { fg = c.teal }
          hl.CmpItemKindProperty = { fg = c.teal }

          -- スニペット
          hl.CmpItemKindSnippet = { fg = c.red }
        end,
      })
      vim.cmd([[colorscheme tokyonight]])
    end,
  },

  -- Statusline
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          component_separators = { left = "|", right = "|" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- Floating statusline for each window
  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    config = function()
      local helpers = require("incline.helpers")
      require("incline").setup({
        window = {
          padding = 0,
          margin = { horizontal = 0, vertical = 0 },
        },
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":.")
          if filename == "" then
            filename = "[No Name]"
          end
          local ft_icon, ft_color = require("nvim-web-devicons").get_icon_color(filename)
          local modified = vim.bo[props.buf].modified
          return {
            ft_icon and { " ", ft_icon, " ", guibg = ft_color, guifg = helpers.contrast_color(ft_color) } or "",
            " ",
            { filename, gui = modified and "bold,italic" or "bold" },
            modified and { " ●", guifg = "#ff6b6b", gui = "bold" } or "",
            " ",
            guibg = "#44406e",
          }
        end,
      })
    end,
  },

  -- Keymap guide
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        preset = "modern",
        delay = 500,
      })

      -- キーマップのグループ名を設定
      require("which-key").add({
        { "<leader>c", group = "Code/Copy" },
        { "<leader>e", group = "Explorer" },
        { "<leader>f", group = "Find" },
        { "<leader>g", group = "Git" },
        { "<leader>h", group = "Hunk" },
        { "<leader>t", group = "Toggle" },
      })
    end,
  },

  -- Telescope（ファジーファインダー）
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = {
            "%.git/",
            "node_modules/",
            "%.DS_Store"
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            no_ignore = true,
          },
        },
      })

      local builtin = require("telescope.builtin")
      -- 一般的なTelescope keymaps
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<C-p>", builtin.find_files, { desc = "Find files (VSCode style)" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<C-f>", builtin.live_grep, { desc = "Live grep (VSCode style)" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
    end,
  },

  -- Cybu (VSCode-style Ctrl+Tab buffer switcher)
  {
    "ghillb/cybu.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-lua/plenary.nvim" },
    config = function()
      require("cybu").setup({
        display_time = 750,  -- メニュー表示時間（ミリ秒）
        behavior = {
          mode = {
            last_used = {
              switch = "immediate",    -- すぐにバッファ切り替え
              view = "paging",         -- ページング表示
            },
          },
        },
      })

      -- VSCode風のCtrl+Tabでバッファ切り替え
      vim.keymap.set("n", "<C-Tab>", "<Plug>(CybuLastusedNext)", { desc = "Next buffer (MRU)" })
      vim.keymap.set("n", "<C-S-Tab>", "<Plug>(CybuLastusedPrev)", { desc = "Previous buffer (MRU)" })
    end,
  },

  -- Git integration
  {
    "tpope/vim-fugitive",
    config = function()
      vim.keymap.set("n", "<leader>gs", ":Git<CR>", { desc = "Git status" })
      vim.keymap.set("n", "<leader>gd", ":Git diff --staged<CR>", { desc = "Git diff staged" })
    end,
  },

  -- Lazygit
  {
    "kdheepak/lazygit.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      vim.keymap.set("n", "<leader>gg", ":LazyGit<CR>", { desc = "Open LazyGit" })
      vim.keymap.set("n", "<C-g>", ":LazyGit<CR>", { desc = "Open LazyGit (VSCode style)" })

      -- lazygitのターミナルバッファでEscキーを押すとlazygitを閉じる
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*lazygit*",
        callback = function()
          vim.keymap.set("t", "<Esc>", "<cmd>close<CR>", { buffer = true, desc = "Close LazyGit" })
        end,
      })
    end,
  },

  -- Git signs
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
        },
        current_line_blame = true,  -- 常にBlame表示
        current_line_blame_opts = {
          delay = 300,
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then return "]c" end
            vim.schedule(function() gs.next_hunk() end)
            return "<Ignore>"
          end, { expr = true, desc = "Next hunk" })

          map("n", "[c", function()
            if vim.wo.diff then return "[c" end
            vim.schedule(function() gs.prev_hunk() end)
            return "<Ignore>"
          end, { expr = true, desc = "Previous hunk" })

          -- Actions
          map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
          map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
          map("v", "<leader>hs", function() gs.stage_hunk({vim.fn.line("."), vim.fn.line("v")}) end, { desc = "Stage hunk" })
          map("v", "<leader>hr", function() gs.reset_hunk({vim.fn.line("."), vim.fn.line("v")}) end, { desc = "Reset hunk" })
          map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
          map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
          map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
          map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
          map("n", "<leader>hb", function() gs.blame_line({full=true}) end, { desc = "Blame line" })
          map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle blame" })
          map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
          map("n", "<leader>hD", function() gs.diffthis("~") end, { desc = "Diff this ~" })

          -- Text object
          map({"o", "x"}, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
        end,
      })
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      -- netrwを無効化（nvim-treeと競合するため）
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      require("nvim-tree").setup({
        sort = {
          sorter = "case_sensitive",
        },
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
          git_ignored = false,
        },
      })

      -- キーマップ
      vim.keymap.set("n", "<leader>ef", ":NvimTreeFindFile<CR>", { desc = "Find current file in explorer" })
      vim.keymap.set("n", "<C-e>", ":NvimTreeFindFile<CR>", { desc = "Find current file in explorer (VSCode style)" })
    end,
  },

  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "query",
          "typescript", "javascript", "tsx",
          "rust",
          "html", "css", "json", "yaml", "markdown",
        },
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },

  -- Commenting
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup({
        toggler = {
          line = "gcc",
          block = "gbc",
        },
        opleader = {
          line = "gc",
          block = "gb",
        },
      })
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
      -- cmpとの統合
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },

  -- GitHub Copilot
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },

  {
    "zbirenbaum/copilot-cmp",
    dependencies = { "copilot.lua" },
    config = function()
      require("copilot_cmp").setup()
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = {
            border = "rounded",
            winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,CursorLine:PmenuSel,Search:None",
            scrollbar = true,
          },
          documentation = {
            border = "rounded",
            winhighlight = "Normal:Pmenu,FloatBorder:Pmenu",
          },
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "copilot", group_index = 2 },
          { name = "nvim_lsp", group_index = 2 },
          { name = "luasnip", group_index = 2 },
          { name = "buffer", group_index = 2 },
          { name = "path", group_index = 2 },
        }),
      })
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- Setup mason first
      require("mason").setup()

      -- Setup mason-lspconfig with handlers
      require("mason-lspconfig").setup({
        ensure_installed = { "ts_ls", "lua_ls" },
        handlers = {
          -- Default handler for all servers
          function(server_name)
            vim.lsp.enable(server_name)
          end,
          -- Custom handler for ts_ls
          ts_ls = function()
            vim.lsp.config('ts_ls', {
              filetypes = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
            })
            vim.lsp.enable('ts_ls')
          end,
          -- Custom handler for lua_ls
          lua_ls = function()
            vim.lsp.config('lua_ls', {
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { 'vim' },
                  },
                },
              },
            })
            vim.lsp.enable('lua_ls')
          end,
        },
      })

      -- LSPAttachイベントを使用してキーマッピングを設定
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

          -- Buffer local mappings.
          local opts = { buffer = ev.buf }
          vim.keymap.set('n', '<F12>', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', '<F24>', vim.lsp.buf.references, opts)  -- Shift+F12
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
          vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        end,
      })
    end,
  },

  -- IME自動切り替え（macOS）
  {
    "keaising/im-select.nvim",
    config = function()
      require("im_select").setup({
        default_command = "macism",
        default_im_select = "com.apple.keylayout.ABC",
      })
    end,
  },

  -- スムーズカーソルアニメーション
  {
    "sphamba/smear-cursor.nvim",
    opts = {
      stiffness = 0.8,               -- より速い反応速度（デフォルト: 0.6）
      trailing_stiffness = 0.6,      -- トレイルも高速化（デフォルト: 0.45）
      time_interval = 12,            -- フレームレート向上（デフォルト: 17ms）
      distance_stop_animating = 0.2, -- 早めにアニメーション停止（デフォルト: 0.1）
    },
  },

})
