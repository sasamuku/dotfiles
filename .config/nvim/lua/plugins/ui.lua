return {
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
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
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
}
