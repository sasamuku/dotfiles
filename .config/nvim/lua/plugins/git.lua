return {
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
      -- Esc は lazygit にそのまま渡す (階層を戻る)。終了は lazygit 標準の q。
      -- プラグインの on_exit は終了コード 0 のときしかウィンドウを閉じない。
      -- 終了コードに関わらず lazygit ターミナルが死んだら確実に閉じる保険。
      vim.api.nvim_create_autocmd("TermClose", {
        pattern = "*lazygit*",
        callback = function(args)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              vim.api.nvim_buf_delete(args.buf, { force = true })
            end
          end)
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

  -- Diffview
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("diffview").setup({
        enhanced_diff_hl = true,  -- より見やすいdiff表示
        use_icons = true,
      })

      -- キーマップ
      vim.keymap.set("n", "<leader>gv", ":DiffviewOpen<CR>", { desc = "Open Diffview" })
      vim.keymap.set("n", "<leader>gc", ":DiffviewClose<CR>", { desc = "Close Diffview" })
      vim.keymap.set("n", "<leader>gh", ":DiffviewFileHistory %<CR>", { desc = "File history (current file)" })
      vim.keymap.set("n", "<leader>gH", ":DiffviewFileHistory<CR>", { desc = "File history (all)" })
    end,
  },
}
