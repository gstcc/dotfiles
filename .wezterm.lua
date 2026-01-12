local w = require("wezterm")
local act = w.action

-- Robust check for Neovim/Vim
local function is_vim(pane)
	local vars = pane:get_user_vars()
	if vars and vars.IS_NVIM == "true" then
		return true
	end
	local process = pane:get_foreground_process_name()
	if process and process:find("n?vim") then
		return true
	end
	return false
end

local config = w.config_builder()

config.term = "wezterm"
config.front_end = "WebGpu"
-- --- APPEARANCE ---
local kanagawa = {
	foreground = "#dcd7ba",
	background = "#1b1b23",
	cursor_bg = "#9CABCA",
	cursor_fg = "#252535",
	cursor_border = "#c8c093",
	selection_fg = "#c8c093",
	selection_bg = "#2d4f67",
	ansi = { "#090618", "#c34043", "#98BB6C", "#c0a36e", "#7e9cd8", "#957fb8", "#6a9589", "#c8c093" },
	brights = { "#727169", "#e82424", "#98bb6c", "#e6c384", "#7fb4ca", "#938aa9", "#7aa89f", "#dcd7ba" },
}

config.color_schemes = { ["My Kanagawa"] = kanagawa }
config.color_scheme = "My Kanagawa"
config.font = w.font("JetBrains Mono", { weight = "Medium" })
config.font_size = 16
config.line_height = 1.55
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.window_decorations = "RESIZE"

config.colors = {
	tab_bar = {
		background = kanagawa.background,
		active_tab = { bg_color = kanagawa.ansi[1], fg_color = kanagawa.brights[5] },
		inactive_tab = { bg_color = kanagawa.background, fg_color = kanagawa.brights[8] },
	},
}

-- --- KEYBOARD SHORTCUTS ---
local direction_keys = { h = "Left", j = "Down", k = "Up", l = "Right" }

local function split_nav(resize_or_move, key)
	return {
		key = key,
		mods = resize_or_move == "resize" and "META" or "CTRL",
		action = w.action_callback(function(win, pane)
			if is_vim(pane) then
				win:perform_action(
					{ SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" } },
					pane
				)
			else
				if resize_or_move == "resize" then
					win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
				else
					win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
				end
			end
		end),
	}
end

config.keys = {
	-- Essentials
	{ key = "r", mods = "CTRL|SHIFT", action = act.ReloadConfiguration },
	{ key = "l", mods = "CTRL|SHIFT", action = act.ShowDebugOverlay }, -- Changed to SHIFT to avoid clear-screen conflict

	-- Split Management
	{ key = "a", mods = "CTRL", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "s", mods = "CTRL|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "f", mods = "CTRL", action = act.TogglePaneZoomState },
	{ key = "q", mods = "CTRL|SHIFT", action = act.CloseCurrentPane({ confirm = true }) },

	-- Search & Copy (Fixed Conflicts)
	{
		key = "f",
		mods = "CTRL|SHIFT",
		action = act.Search({ CaseInSensitiveString = "" }),
	},
	{ key = "x", mods = "CTRL", action = act.ActivateCopyMode },

	-- Lazygit (Changed from ZSH to Bash)
	{
		key = "g",
		mods = "CTRL",
		action = w.action_callback(function(win, pane)
			win:perform_action(act.SplitHorizontal({ args = { "bash", "-li", "-c", "lazygit" } }), pane)
			win:perform_action(act.SetPaneZoomState(true), pane)
		end),
	},

	-- Quick URL Select
	{
		key = "i",
		mods = "CTRL|SHIFT",
		action = act.QuickSelectArgs({
			label = "open url",
			patterns = { "https?://\\S+" },
			action = w.action_callback(function(window, pane)
				local url = window:get_selection_text_for_pane(pane)
				w.open_with(url)
			end),
		}),
	},

	-- Smart Splits (Vim Integration)
	split_nav("move", "h"),
	split_nav("move", "j"),
	split_nav("move", "k"),
	split_nav("move", "l"),
	split_nav("resize", "h"),
	split_nav("resize", "j"),
	split_nav("resize", "k"),
	split_nav("resize", "l"),
}

-- --- BEHAVIOR ---
config.scrollback_lines = 10000
config.adjust_window_size_when_changing_font_size = false

w.on("update-right-status", function(window, pane)
	local name = window:active_key_table()
	if name then
		name = "TABLE: " .. name
	end

	-- Check if we are in a special mode
	local status = ""
	if window:leader_is_active() then
		status = "LEADER"
	end

	-- Display the current mode
	window:set_right_status(w.format({
		{ Foreground = { Color = "#98BB6C" } },
		{ Text = status .. (name or "") .. "  " },
		{ Foreground = { Color = "#dcd7ba" } },
		{ Text = w.strftime("%H:%M  ") },
	}))
end)

return config
