-- Pull in the wezterm API
local wezterm = require("wezterm")

function update_overrides_if_changed(window, new_config)
	local overrides = window:get_config_overrides() or {}
	local diff = false
	for k, v in pairs(new_config) do
		if overrides[k] ~= v then
			diff = true
			overrides[k] = v
		end
	end
	if diff then
		window:set_config_overrides(overrides)
	end
end

-- Hide window decoration when full screen and only one tab.
wezterm.on("window-resized", function(window, pane)
	local new_config
	if window:get_dimensions().is_full_screen then
		new_config = {
			hide_tab_bar_if_only_one_tab = true,
			window_decorations = "RESIZE",
			use_fancy_tab_bar = false,
		}
	else
		new_config = {
			hide_tab_bar_if_only_one_tab = false,
			window_decorations = "INTEGRATED_BUTTONS|RESIZE",
			use_fancy_tab_bar = true,
		}
	end
	update_overrides_if_changed(window, new_config)
end)

-- This will hold the configuration.
local config = wezterm.config_builder()

-- config.font = wezterm.font("JetBrains Mono", { weight = "Bold", italic = true })

font = wezterm.font_with_fallback({
	"IBM Plex Mono",
	"Noto Sans SC",
	"WenQuanYi Micro Hei",
	"Source Han Sans SC",
	"Noto Sans CJK SC",
})

config.warn_about_missing_glyphs = false

config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
	regex = [[\b[tt](\d+)\b]],
	format = "https://example.com/tasks/?t=$1",
	highlight = 1,
})

-- make username/project paths clickable. this implies paths like the following are for github.
-- ( "nvim-treesitter/nvim-treesitter" | wbthomason/packer.nvim | wezterm/wezterm | "wezterm/wezterm.git" )
-- as long as a full url hyperlink regex exists above this it should not match a full url to
-- github or gitlab / bitbucket (i.e. https://gitlab.com/user/project.git is still a whole clickable url)
table.insert(config.hyperlink_rules, {
	regex = [[["]?([\w\d]{1}[-\w\d]+)(/){1}([-\w\d\.]+)["]?]],
	format = "https://www.github.com/$1/$3",
	highlight = 1,
})

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "Catppuccin Mocha"
config.font_size = 13
config.line_height = 1.2
config.cell_width = 0.9

local action = wezterm.action
config.keys = {
	{
		key = "n",
		mods = "SHIFT|CTRL",
		action = wezterm.action.ToggleFullScreen,
	},
	-- Split vertically (left/right)
	{ key = "|", mods = "CTRL|SHIFT", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Split horizontally (top/bottom)
	{ key = "_", mods = "CTRL|SHIFT", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "LeftArrow", mods = "SHIFT|ALT", action = action.MoveTabRelative(-1) },
	{ key = "RightArrow", mods = "SHIFT|ALT", action = action.MoveTabRelative(1) },
}

config.enable_kitty_graphics = true
config.term = "xterm-256color"
config.window_decorations = "NONE"
config.enable_tab_bar = false

-- and finally, return the configuration to wezterm
return config
