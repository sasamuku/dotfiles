-- noice.nvim: コマンドライン・メッセージ・通知の UI を刷新
-- statusline 非表示構成（laststatus=0）と組み合わせ、メッセージを画面下に頼らず表示する
-- 構成は izumin5210/dotfiles を参考（独自 palette/util 依存は除去し tokyonight 前提に簡略化）
return {
  {
    "rcarriga/nvim-notify",
    version = "*",
    lazy = true,
    opts = {
      render = "wrapped-compact",
      stages = "static",
      top_down = false, -- 通知を右下から上に積む
      timeout = 5000,
      max_height = function()
        return math.floor(vim.o.lines * 0.75)
      end,
      max_width = function()
        return math.floor(vim.o.columns * 0.5)
      end,
    },
  },
  {
    "folke/noice.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      lsp = {
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
          ["cmp.entry.get_documentation"] = true,
        },
        signature = { enabled = true },
        progress = { enabled = true },
        hover = { enabled = false },
      },
      presets = {
        bottom_search = false,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
      messages = {
        view_search = false,
      },
      routes = {
        -- hover 情報なしの通知は抑制
        {
          filter = { event = "notify", find = "No information available" },
          opts = { skip = true },
        },
      },
    },
  },
}
