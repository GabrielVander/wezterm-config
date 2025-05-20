local wezterm = require("wezterm")
local config = wezterm.config_builder()

wezterm.on("update-right-status", function(window, pane)
	window:set_right_status(window:active_workspace())
end)

-- Configure everything here on the `config` object

-- APPEARANCE
config.color_scheme = "Catppuccin Mocha"

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
config.window_background_opacity = 0.90
config.window_decorations = "RESIZE"

config.font_size = 11
config.font = wezterm.font({
	family = "JetBrainsMono Nerd Font",
	weight = "DemiBold",
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
config.mouse_bindings = {
	-- Open URLs with LEADER+Click
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "LEADER",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
}
config.leader = { key = "m", mods = "ALT", timeout_milliseconds = 2000 }
config.keys = {
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
		mods = "LEADER|SHIFT",
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

	-- Rename current tab
	{
		key = "C",
		mods = "LEADER|SHIFT",
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
		mods = "LEADER",
		key = "m",
		action = wezterm.action.PaneSelect,
	},
	-- Use CTRL + [h|j|k|l] to move between panes
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

	-- Move to another pane (next or previous)
	{
		key = "[",
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection("Prev"),
	},
	{
		key = "]",
		mods = "CTRL",
		action = wezterm.action.ActivatePaneDirection("Next"),
	},

	-- Move to another tab (next or previous)
	{
		key = "{",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTabRelative(-1),
	},
	{
		key = "}",
		mods = "CTRL|SHIFT",
		action = wezterm.action.ActivateTabRelative(1),
	},

	-- Move to anoher workspace (next or previous)
	{ key = "{", mods = "CTRL|SHIFT|ALT", action = wezterm.action.SwitchWorkspaceRelative(-1) },
	{ key = "}", mods = "CTRL|SHIFT|ALT", action = wezterm.action.SwitchWorkspaceRelative(1) },

	-- Prompt for a name to use for a new workspace and switch to it.
	{
		key = "T",
		mods = "LEADER|CTRL|SHIFT",
		action = wezterm.action.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter name for new workspace" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:perform_action(
						wezterm.action.SwitchToWorkspace({
							name = line,
						}),
						pane
					)
				end
			end),
		}),
	},

	-- Rename workspace
	{
		key = "T",
		mods = "LEADER|SHIFT",
		action = wezterm.action.PromptInputLine({
			description = "(wezterm) Set workspace title:",
			action = wezterm.action_callback(function(win, pane, line)
				if line then
					wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
				end
			end),
		}),
	},
	-- Launch workspace selection
	{
		key = "t",
		mods = "LEADER",
		action = wezterm.action_callback(function(win, pane)
			-- create workspace list
			local workspaces = {}
			for i, name in ipairs(wezterm.mux.get_workspace_names()) do
				table.insert(workspaces, {
					id = name,
					label = string.format("%d. %s", i, name),
				})
			end
			win:perform_action(
				wezterm.action.InputSelector({
					action = wezterm.action_callback(function(_, _, id, label)
						if not id and not label then
							wezterm.log_info("Workspace selection canceled") -- 入力が空ならキャンセル
						else
							win:perform_action(wezterm.action.SwitchToWorkspace({ name = id }), pane) -- workspace を移動
						end
					end),
					title = "Select workspace",
					choices = workspaces,
					fuzzy = true,
					-- fuzzy_description = string.format("Select workspace: %s -> ", current), -- requires nightly build
				}),
				pane
			)
		end),
	},
	-- Use LEADER+Shift+S t swap the active pane and another one
	{
		key = "s",
		mods = "LEADER|SHIFT",
		action = wezterm.action({
			PaneSelect = { mode = "SwapWithActiveKeepFocus" },
		}),
	},

	-- Use LEADER+w to close the pane, LEADER+SHIFT+w to close the tab
	{
		key = "w",
		mods = "LEADER",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "w",
		mods = "LEADER|SHIFT",
		action = wezterm.action.CloseCurrentTab({ confirm = true }),
	},

	-- Use LEADER+z to enter zoom state
	{
		key = "z",
		mods = "LEADER",
		action = wezterm.action.TogglePaneZoomState,
	},

	-- -- Launch commands in a new pane
	-- {
	-- 	key = "g",
	-- 	mods = "LEADER",
	-- 	action = wezterm.action.SplitHorizontal({
	-- 		args = { os.getenv("SHELL"), "-c", "lg" },
	-- 	}),
	-- },
}

return config
