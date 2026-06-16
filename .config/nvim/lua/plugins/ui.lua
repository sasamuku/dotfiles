return {
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        -- 背景を描画せずターミナル (ghostty/cmux) の背景色・透過度をそのまま使う
        transparent = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
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

  -- Floating statusline for each window
  -- render は izumin5210/dotfiles を参考に diagnostics / readonly / active 区別を実装
  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    config = function()
      local devicons = require("nvim-web-devicons")
      local c = require("tokyonight.colors").setup({ style = "night" })
      local get_display_filename_and_dirname =
        require("plugins.incline.get_display_filename_and_dirname")

      local fg_active = c.magenta
      local fg_inactive = c.dark3
      local icons = { error = "󰅚 ", warn = "󰀪 ", hint = "󰌶 ", info = " " }

      -- diagnostics 件数をアイコン付きで返す（focused のときだけ色を付ける）
      ---@param props { buf: number, win: number, focused: boolean }
      local function get_diagnostic_label(props)
        local label = {}
        for severity, icon in pairs(icons) do
          local n = #vim.diagnostic.get(props.buf, {
            severity = vim.diagnostic.severity[string.upper(severity)],
          })
          if n > 0 then
            table.insert(label, {
              icon .. n .. " ",
              group = props.focused and ("DiagnosticSign" .. severity) or "NonText",
            })
          end
        end
        if #label > 0 then
          table.insert(label, { "┊ ", guifg = fg_inactive })
        end
        return label
      end

      ---@param props { buf: number, win: number, focused: boolean }
      local function render(props)
        local filename, dirname = get_display_filename_and_dirname(props.buf)
        local ft_icon, ft_color = devicons.get_icon_color(filename)

        local has_error = #vim.diagnostic.get(props.buf, {
          severity = vim.diagnostic.severity["ERROR"],
        }) > 0
        local is_readonly = vim.bo[props.buf].readonly

        local fg_filename_active = has_error and c.red
          or (is_readonly and c.dark3 or fg_active)
        local fg_filename = props.focused and fg_filename_active or fg_inactive

        return {
          { get_diagnostic_label(props) },
          {
            (ft_icon and ft_icon .. " " or ""),
            guifg = props.focused and ft_color or fg_inactive,
          },
          {
            (is_readonly and " " or ""),
            guifg = fg_filename,
          },
          {
            dirname and dirname .. "/" or "",
            guifg = fg_inactive,
          },
          {
            filename,
            guifg = fg_filename,
            gui = props.focused and "bold" or "",
          },
          {
            vim.bo[props.buf].modified and " ●" or "",
            guifg = props.focused and c.orange or fg_inactive,
          },
        }
      end

      require("incline").setup({
        highlight = {
          groups = {
            InclineNormal = { guibg = c.bg_dark, guifg = fg_active },
            InclineNormalNC = { guibg = "none", guifg = fg_inactive },
          },
        },
        window = {
          options = { winblend = 0 },
          placement = { horizontal = "right", vertical = "top" },
          margin = { horizontal = 0, vertical = 0 },
          padding = 2,
        },
        render = render,
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

  -- モードに応じて cursorline / 行番号を色付け
  {
    "mvllow/modes.nvim",
    tag = "v0.2.1",
    event = "VeryLazy",
    config = function()
      local c = require("tokyonight.colors").setup({ style = "night" })
      require("modes").setup({
        colors = {
          copy = c.yellow,
          delete = c.red,
          change = c.red,
          format = c.orange,
          insert = c.green,
          replace = c.blue,
          select = c.magenta,
          visual = c.magenta,
        },
        -- 透過背景だと一律 0.15 は薄すぎて選択範囲が見えないため、
        -- visual だけ濃くする (cursorline はうるさくならないよう控えめに保つ)
        line_opacity = {
          visual = 0.4,
          select = 0.4,
          copy = 0.15,
          delete = 0.15,
          change = 0.15,
          format = 0.15,
          insert = 0.15,
          replace = 0.15,
        },
        -- カーソルの見た目は smear-cursor.nvim に任せる（両者が guicursor を奪い合うのを防ぐ）
        set_cursor = false,
        ignore = { "NvimTree", "TelescopePrompt", "which-key", "lazy", "fugitive", "help" },
      })
    end,
  },
}
