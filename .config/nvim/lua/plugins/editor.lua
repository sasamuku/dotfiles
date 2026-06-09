return {
  -- Telescope（ファジーファインダー）
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local actions = require("telescope.actions")
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<esc>"] = actions.close,  -- インサートモードでESC 1回で閉じる
            },
          },
          file_ignore_patterns = {
            "%.git/",
            "node_modules/",
            "%.DS_Store",
            "%.cache/",
            "build/",
            "dist/",
            "target/",
            "%.next/",
            "%.nuxt/",
            "%.output/",
            "coverage/",
            "%.lock$",
            "package%-lock%.json",
            "yarn%.lock",
            "pnpm%-lock%.yaml",
          },
          -- プレビューのファイルサイズ制限（100KB）
          preview = {
            filesize_limit = 0.1,
            timeout = 250,
          },
          -- ソート戦略の最適化
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            -- no_ignoreを削除: .gitignoreを尊重する
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

  -- Buffer Manager (VSCode-style Ctrl+Tab buffer switcher)
  {
    "j-morano/buffer_manager.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("buffer_manager").setup({
        select_menu_item_commands = {
          edit = {
            key = "<CR>",
            command = "edit"
          },
          v = {
            key = "<C-v>",
            command = "vsplit"
          },
          h = {
            key = "<C-h>",
            command = "split"
          }
        },
        focus_alternate_buffer = false,
        short_file_names = true,
        short_term_names = true,
        loop_nav = true,
        order_buffers = "lastused",  -- 最近使用した順に表示
        show_indicators = "after",
      })

      local bmui = require("buffer_manager.ui")

      -- Ctrl+Tabでバッファメニューを開く
      vim.keymap.set("n", "<C-Tab>", bmui.toggle_quick_menu, { desc = "Open buffer menu" })

      -- 次/前のバッファへ移動（メニューを開かずに）
      vim.keymap.set("n", "<C-S-Tab>", bmui.nav_prev, { desc = "Previous buffer (MRU)" })
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- netrwを無効化
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      -- <C-e>: 開いていれば閉じる、閉じていれば開いて現在ファイルを探す
      local function smart_toggle()
        local api = require("nvim-tree.api")
        if api.tree.is_visible() then
          api.tree.close()
        else
          api.tree.find_file({ open = true, focus = true })
        end
      end

      -- nvim-tree にフォーカスがあるときも <C-e> でトグルできるようにする
      local function on_attach(bufnr)
        local api = require("nvim-tree.api")
        -- デフォルトのキーマップを引き継ぐ
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.set("n", "<C-e>", smart_toggle, {
          buffer = bufnr,
          desc = "nvim-tree: Smart toggle (close/open)",
          noremap = true,
          silent = true,
          nowait = true,
        })
      end

      require("nvim-tree").setup({
        on_attach = on_attach,
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
        update_focused_file = {
          enable = true,
          update_cwd = false,
        },
        view = {
          width = {
            min = 30,
            max = -1,  -- -1 = 無制限。最長のファイル名に合わせて自動拡張
          },
          side = "left",
        },
        renderer = {
          icons = {
            glyphs = {
              folder = {
                default = "",
                open = "",
                empty = "",
              },
              git = {
                unstaged = "✗",
                staged = "✓",
                unmerged = "",
                renamed = "➜",
                untracked = "★",
                deleted = "✖",
                ignored = "◌",
              },
            },
          },
        },
        filters = {
          dotfiles = false,
          custom = { ".DS_Store" },
        },
        git = {
          enable = true,
          ignore = false,
        },
        filesystem_watchers = {
          enable = true,  -- ファイル変更を自動検知
        },
        actions = {
          open_file = {
            quit_on_open = false,
          },
        },
      })

      -- キーマップ
      vim.keymap.set("n", "<leader>ee", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
      vim.keymap.set("n", "<leader>ef", ":NvimTreeFindFile<CR>", { desc = "Find current file in explorer" })
      vim.keymap.set("n", "<C-e>", smart_toggle, { desc = "Toggle explorer / find current file (VSCode style)" })
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
          "go", "gomod", "gosum",
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
}
