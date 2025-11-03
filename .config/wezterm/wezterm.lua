local wezterm = require('wezterm')
local config = wezterm.config_builder()

-- Color scheme
config.color_scheme = 'Tokyo Night'

-- Font
config.font = wezterm.font('PlemolJP Console NF', { weight = 'Regular' })
config.font_size = 12.0

-- Window
config.initial_cols = 140
config.initial_rows = 45
config.window_background_opacity = 0.90
config.macos_window_background_blur = 20
config.window_decorations = 'RESIZE'
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}

-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.show_tab_index_in_tab_bar = false
config.tab_bar_at_bottom = false

-- Tab bar colors
config.colors = {
  tab_bar = {
    background = '#1a1b26',
    active_tab = {
      bg_color = '#7aa2f7',
      fg_color = '#1a1b26',
      intensity = 'Bold',
    },
    inactive_tab = {
      bg_color = '#292e42',
      fg_color = '#565f89',
    },
    inactive_tab_hover = {
      bg_color = '#3b4261',
      fg_color = '#c0caf5',
    },
    new_tab = {
      bg_color = '#1a1b26',
      fg_color = '#565f89',
    },
    new_tab_hover = {
      bg_color = '#3b4261',
      fg_color = '#c0caf5',
    },
  },
}

-- Pane visual settings
config.inactive_pane_hsb = {
  saturation = 0.5,
  brightness = 0.4,
}

-- Misc
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.audible_bell = 'Disabled'

-- Keybindings
config.keys = {
  -- Tab management
  {
    key = 't',
    mods = 'CMD',
    action = wezterm.action.SpawnTab 'CurrentPaneDomain',
  },
  {
    key = 'Tab',
    mods = 'CTRL',
    action = wezterm.action.ActivateTabRelative(1),
  },
  {
    key = 'Tab',
    mods = 'CTRL|SHIFT',
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    key = '[',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ActivateTabRelative(-1),
  },
  {
    key = ']',
    mods = 'CMD|SHIFT',
    action = wezterm.action.ActivateTabRelative(1),
  },
  -- Split panes
  {
    key = 'd',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'd',
    mods = 'CMD|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  -- Navigate panes
  {
    key = '[',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Prev',
  },
  {
    key = ']',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Next',
  },
  -- Close pane
  {
    key = 'w',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  -- Line editing
  {
    key = 'Delete',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'k', mods = 'CTRL' },
  },
  {
    key = 'Backspace',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'u', mods = 'CTRL' },
  },
  -- Cursor movement
  -- Option + Left/Right: word movement
  {
    key = 'LeftArrow',
    mods = 'OPT',
    action = wezterm.action.SendKey { key = 'b', mods = 'ALT' },
  },
  {
    key = 'RightArrow',
    mods = 'OPT',
    action = wezterm.action.SendKey { key = 'f', mods = 'ALT' },
  },
  -- Command + Left/Right: line start/end
  {
    key = 'LeftArrow',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'a', mods = 'CTRL' },
  },
  {
    key = 'RightArrow',
    mods = 'CMD',
    action = wezterm.action.SendKey { key = 'e', mods = 'CTRL' },
  },
}

-- Tab title format: show current directory
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local pane = tab.active_pane
  local cwd = pane.current_working_dir

  if cwd then
    local path = cwd.file_path or cwd
    -- Remove file:// prefix if present
    path = path:gsub('file://[^/]*', '')
    -- Extract only the directory name (last component)
    local dir_name = path:match("([^/]+)/?$") or path
    return {
      { Text = ' ' .. dir_name .. ' ' },
    }
  end

  return tab.active_pane.title
end)

return config
