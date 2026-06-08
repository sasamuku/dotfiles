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

-- ビジュアルモードの選択範囲（開始行・終了行）を取得
local function get_visual_range()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  if start_line == 0 then
    start_line = vim.fn.line(".")
  end
  return start_line, end_line
end

-- インサートモードを抜けて保存
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

-- GitHub リモートURL をコピー
vim.keymap.set("n", "<leader>cr", function()
  local path = get_current_file_path()
  local url = vim.fn.system("gh browse " .. path .. " --commit --no-browser 2>&1")
  url = url:gsub("%s+$", "")  -- 末尾の改行を削除

  if vim.v.shell_error == 0 then
    vim.fn.setreg("+", url)
    print("Copied GitHub URL: " .. url)
  else
    print("Error: Could not get GitHub URL")
  end
end, { desc = "Copy GitHub remote URL" })

-- GitHub リモートURL をコピー（行番号付き、ビジュアルモード）
vim.keymap.set("v", "<leader>cr", function()
  local path = get_current_file_path()
  local start_line, end_line = get_visual_range()

  local line_part
  if start_line == end_line then
    line_part = ":" .. start_line
  else
    line_part = ":" .. start_line .. "-" .. end_line
  end

  local url = vim.fn.system("gh browse " .. path .. line_part .. " --commit --no-browser 2>&1")
  url = url:gsub("%s+$", "")  -- 末尾の改行を削除

  if vim.v.shell_error == 0 then
    vim.fn.setreg("+", url)
    if start_line == end_line then
      print("Copied GitHub URL with line " .. start_line)
    else
      print("Copied GitHub URL with lines " .. start_line .. "-" .. end_line)
    end
  else
    print("Error: Could not get GitHub URL")
  end
end, { desc = "Copy GitHub remote URL with lines" })

-- GitHub でファイルを開く
vim.keymap.set("n", "<leader>go", function()
  local path = get_current_file_path()
  vim.cmd("!gh browse " .. path .. " --commit")
  print("Opening: " .. path .. " in GitHub at current commit")
end, { desc = "Open file in GitHub at current commit" })

-- GitHub でファイルを行番号付きで開く（ビジュアルモード）
vim.keymap.set("v", "<leader>go", function()
  local path = get_current_file_path()
  local start_line, end_line = get_visual_range()

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
