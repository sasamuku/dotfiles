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
      -- Ctrl+b でもバッファ検索（Ctrl+Tab は cmux の surface 切替に取られるため使えない）
      vim.keymap.set("n", "<C-b>", builtin.buffers, { desc = "Find buffers (VSCode style)" })
    end,
  },

  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      -- netrwを無効化（neo-treeと競合するため）
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      -- <C-e>: フロートが開いていれば閉じ、閉じていれば現在ファイルを表示して開く
      local function float_toggle()
        local mgr = require("neo-tree.sources.manager")
        local renderer = require("neo-tree.ui.renderer")
        local state = mgr.get_state("filesystem")
        if state and renderer.window_exists(state) then
          require("neo-tree.command").execute({ action = "close" })
        else
          require("neo-tree.command").execute({
            action = "focus",
            source = "filesystem",
            position = "float",
            reveal = true,
          })
        end
      end

      require("neo-tree").setup({
        close_if_last_window = true,
        popup_border_style = "rounded",
        enable_git_status = true,
        enable_diagnostics = true,
        default_component_configs = {
          indent = {
            padding = 0,
            with_expanders = true,
          },
          icon = {
            folder_closed = "",
            folder_open = "",
            folder_empty = "",
          },
          git_status = {
            symbols = {
              added = "+",
              modified = "~",
              deleted = "✖",
              renamed = "➜",
              untracked = "★",
              ignored = "◌",
              unstaged = "✗",
              staged = "✓",
              conflict = "",
            },
          },
        },
        window = {
          -- メインのファイラーをサイドバーではなくフロートで表示する
          position = "float",
          mappings = {
            ["<space>"] = "none",
            ["o"] = "open",
            -- フロート内でも <C-e> で閉じられるようにする
            ["<C-e>"] = "close_window",
          },
        },
        filesystem = {
          follow_current_file = {
            enabled = true,
            leave_dirs_open = false,
          },
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_by_name = {
              ".DS_Store",
            },
          },
          -- フォーカス不要でファイル/git 変更を自動検知（過去の戻し理由への対策）
          use_libuv_file_watcher = true,
        },
        buffers = {
          follow_current_file = {
            enabled = true,
          },
        },
      })

      -- キーマップ
      vim.keymap.set("n", "<leader>ee", float_toggle, { desc = "Toggle file explorer (float)" })
      vim.keymap.set("n", "<leader>ef", ":Neotree reveal position=float<CR>", { desc = "Find current file in explorer" })
      vim.keymap.set("n", "<C-e>", float_toggle, { desc = "Toggle float explorer (VSCode style)" })
    end,
  },

  -- Treesitter (main ブランチ: Neovim 0.12 対応。master は 0.11 用 legacy で query API 非互換)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local parsers = {
        "lua", "vim", "vimdoc", "query",
        "typescript", "javascript", "tsx",
        "rust",
        "go", "gomod", "gosum",
        "html", "css", "json", "yaml", "markdown", "markdown_inline",
      }

      require("nvim-treesitter").install(parsers)

      -- main ブランチは highlight を自前で有効化する必要がある
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("UserTreesitterHighlight", {}),
        callback = function(ev)
          -- パーサが利用可能なバッファだけ起動する
          local ok = pcall(vim.treesitter.start, ev.buf)
          if ok then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  -- Markdown のバッファ内レンダリング（カーソル行のみ生テキストに戻る）
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      -- 見出しは番号アイコンに置き換えず # をそのまま表示する
      heading = { icons = {} },
    },
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
