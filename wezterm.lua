local os = require("os")
local wezterm = require("wezterm")
local mux = wezterm.mux
local session_manager = require("wezterm-session-manager/session-manager")

-- Session Manager event bindings
-- See https://github.com/danielcopper/wezterm-session-manager
wezterm.on("save_session", function(window)
	session_manager.save_state(window)
end)
wezterm.on("load_session", function(window)
	session_manager.load_state(window)
end)
wezterm.on("restore_session", function(window)
	session_manager.restore_state(window)
end)

-- Wezterm <-> nvim pane navigation
-- https://github.com/aca/wezterm.nvim

local move_around = function(window, pane, direction_wez, direction_nvim)
	local result = os.execute(
		"env NVIM_LISTEN_ADDRESS=/tmp/nvim"
			.. pane:pane_id()
			.. " "
			.. wezterm.home_dir
			.. "/.local/bin/wezterm.nvim.navigator"
			.. " "
			.. direction_nvim
	)
	if result then
		window:perform_action(wezterm.action({ SendString = "\x17" .. direction_nvim }), pane)
	else
		window:perform_action(wezterm.action({ ActivatePaneDirection = direction_wez }), pane)
	end
end

wezterm.on("move-left", function(window, pane)
	move_around(window, pane, "Left", "h")
end)

wezterm.on("move-right", function(window, pane)
	move_around(window, pane, "Right", "l")
end)

wezterm.on("move-up", function(window, pane)
	move_around(window, pane, "Up", "k")
end)

wezterm.on("move-down", function(window, pane)
	move_around(window, pane, "Down", "j")
end)

local vim_resize = function(window, pane, direction_wez, direction_nvim)
	local result = os.execute(
		"env NVIM_LISTEN_ADDRESS=/tmp/nvim"
			.. pane:pane_id()
			.. " "
			.. wezterm.home_dir
			.. "/.local/bin/wezterm.nvim.navigator"
			.. " "
			.. direction_nvim
	)
	if result then
		window:perform_action(wezterm.action({ SendString = "\x1b" .. direction_nvim }), pane)
	else
		window:perform_action(wezterm.action({ ActivatePaneDirection = direction_wez }), pane)
	end
end

wezterm.on("resize-left", function(window, pane)
	vim_resize(window, pane, "Left", "h")
end)

wezterm.on("resize-right", function(window, pane)
	vim_resize(window, pane, "Right", "l")
end)

wezterm.on("resize-up", function(window, pane)
	vim_resize(window, pane, "Up", "k")
end)

wezterm.on("resize-down", function(window, pane)
	vim_resize(window, pane, "Down", "j")
end)

wezterm.on("update-right-status", function(window, _)
	window:set_right_status(window:active_workspace())
end)

-- Configure everything here on the `config` object

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- LEADER
-- Binding to ctrl-a here to mimic tmux
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }

-- APPEARANCE
config.color_scheme = "Catppuccin Mocha"
config.enable_scroll_bar = true
config.enable_wayland = true
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.colors = {
	tab_bar = {
		active_tab = { fg_color = "#6c7086", bg_color = "#74c7ec" },
	},
}

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.window_background_opacity = 0.98
config.window_decorations = "RESIZE"

config.font_size = 10
config.font = wezterm.font({
	family = "JetBrainsMono Nerd Font",
	weight = "Medium",
})

-- BEHAVIOR
config.default_prog = { "/bin/bash" }
config.launch_menu = {
	{
		label = "bash",
		args = { "/bin/bash" },
	},
}

-- MOUSE & KEY BINDINGS
config.disable_default_key_bindings = true
config.use_dead_keys = false
config.use_ime = true

config.mouse_bindings = {
	-- Open URLs with LEADER+Click
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CTRL",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}
config.keys = {
	-- Activate command palette
	{
		key = "P",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateCommandPalette,
	},

	-- Show tab navigator; similar to listing panes in tmux
	{
		key = "w",
		mods = "LEADER",
		action = wezterm.action.ShowTabNavigator,
	},
	-- Show debug overlay
	{
		key = "L",
		mods = "LEADER|SHIFT",
		action = wezterm.action.ShowDebugOverlay,
	},

	-- Activate Copy mode
	{
		key = "[",
		mods = "LEADER",
		action = wezterm.action.ActivateCopyMode,
	},

	-- Copy/Paste functionality
	{ key = "C", mods = "CTRL|SHIFT", action = wezterm.action.CopyTo("ClipboardAndPrimarySelection") },
	{ key = "V", mods = "CTRL|SHIFT", action = wezterm.action.PasteFrom("Clipboard") },

	-- Show launcher menu
	{
		key = "P",
		mods = "LEADER|SHIFT",
		action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
	},

	-- Vertical pipe (|) -> horizontal split
	{
		key = "|",
		mods = "LEADER|SHIFT",
		action = wezterm.action.SplitHorizontal({
			domain = "CurrentPaneDomain",
		}),
	},

	-- Underscore (_) -> vertical split
	{
		key = "-",
		mods = "LEADER",
		action = wezterm.action.SplitVertical({
			domain = "CurrentPaneDomain",
		}),
	},

	-- Show tab navigator
	{
		key = "c",
		mods = "LEADER",
		action = wezterm.action.ShowTabNavigator,
	},

	-- Spawn new tab
	{
		key = "C",
		mods = "LEADER|CTRL|SHIFT",
		action = wezterm.action.SpawnTab("DefaultDomain"),
	},

	-- Rename current tab; analagous to command in tmux
	{
		key = ",",
		mods = "LEADER",
		action = wezterm.action.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Move to a pane (prompt to which one)
	{
		key = "m",
		mods = "LEADER",
		action = wezterm.action.PaneSelect,
	},

	-- Use CTRL + Shift + [h|j|k|l] to move between panes
	{
		key = "h",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},

	-- ALT + Shift + (h,j,k,l) to resize panes
	{
		key = "h",
		mods = "ALT|SHIFT",
		action = wezterm.action({ EmitEvent = "resize-left" }),
	},
	{
		key = "j",
		mods = "ALT|SHIFT",
		action = wezterm.action({ EmitEvent = "resize-down" }),
	},
	{
		key = "k",
		mods = "ALT|SHIFT",
		action = wezterm.action({ EmitEvent = "resize-up" }),
	},
	{
		key = "l",
		mods = "ALT|SHIFT",
		action = wezterm.action({ EmitEvent = "resize-right" }),
	},
	-- Move to another pane (next or previous)
	{
		key = ";",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Prev"),
	},
	{
		key = "o",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Next"),
	},

	-- Move to another tab (next or previous)
	{
		key = "p",
		mods = "LEADER",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = "n",
		mods = "LEADER",
		action = wezterm.action.ActivateTabRelative(1),
	},

	-- Use LEADER+Shift+{ to swap the active pane and another one
	{
		key = "{",
		mods = "LEADER|SHIFT",
		action = wezterm.action({
			PaneSelect = { mode = "SwapWithActiveKeepFocus" },
		}),
	},

	-- Use LEADER+x to close the pane, LEADER+SHIFT+x to close the tab
	{
		key = "x",
		mods = "LEADER",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "x",
		mods = "LEADER|SHIFT",
		action = wezterm.action.CloseCurrentTab({ confirm = true }),
	},
	-- Use LEADER+z to enter zoom state
	{
		key = "z",
		mods = "LEADER",
		action = wezterm.action.TogglePaneZoomState,
	},

	-- Attach to muxer
	{
		key = "a",
		mods = "LEADER",
		action = wezterm.action.AttachDomain("unix"),
	},

	-- Detach from muxer
	{
		key = "d",
		mods = "LEADER",
		action = wezterm.action.DetachDomain({ DomainName = "unix" }),
	}, -- -- Launch commands in a new pane

	-- Show list of workspaces
	{
		key = "s",
		mods = "LEADER",
		action = wezterm.action.ShowLauncherArgs({ flags = "WORKSPACES" }),
	},

	-- Rename current session; analagous to command in tmux
	{
		key = "$",
		mods = "LEADER|SHIFT",
		action = wezterm.action.PromptInputLine({
			description = "Enter new name for session",
			action = wezterm.action_callback(function(window, _, line)
				if line then
					mux.rename_workspace(window:mux_window():get_workspace(), line)
				end
			end),
		}),
	},

	-- Session manager bindings
	{
		key = "s",
		mods = "LEADER|SHIFT",
		action = wezterm.action({ EmitEvent = "save_session" }),
	},
	{
		key = "L",
		mods = "LEADER|SHIFT",
		action = wezterm.action({ EmitEvent = "load_session" }),
	},
	{
		key = "R",
		mods = "LEADER|SHIFT",
		action = wezterm.action({ EmitEvent = "restore_session" }),
	},
}

return config
