-- リーダーキーの設定
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 表示
vim.opt.number = true              -- 行番号を表示
vim.opt.termguicolors = true       -- 24bit カラーを有効化（tokyonight の発色に必須）
vim.opt.signcolumn = "yes"         -- 常にサインカラムを表示（gitsigns の列ガタつき防止）

-- statusline / tabline を出さない
-- mode は modes.nvim、ファイル名・diagnostics は incline.nvim に分散させている
vim.opt.laststatus = 0             -- statusline を非表示
vim.opt.showtabline = 0            -- tabline を非表示
vim.opt.statusline = "─"           -- 分割境界に残る statusline 行を横線で埋める
vim.opt.fillchars:append({ stl = "─", stlnc = "─" })

-- クリップボード
vim.opt.clipboard = "unnamedplus"  -- システムクリップボードを使用

-- インデント
vim.opt.expandtab = true           -- タブをスペースに変換
vim.opt.tabstop = 2                -- タブ幅を2に設定
vim.opt.shiftwidth = 2             -- インデント幅を2に設定
vim.opt.smartindent = true         -- 賢い自動インデント

-- 検索
vim.opt.ignorecase = true          -- 検索時に大文字小文字を無視
vim.opt.smartcase = true           -- 大文字を含む場合は区別
vim.opt.hlsearch = true            -- 検索結果をハイライト

-- 永続 undo
vim.opt.undofile = true            -- undo 履歴をファイルに保存
