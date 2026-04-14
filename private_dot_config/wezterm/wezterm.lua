local wezterm = require "wezterm"

local config = wezterm.config_builder()
config.automatically_reload_config = true

config.color_scheme = "Hybrid (Gogh)"

config.font_size = 16.0
config.font = wezterm.font("CodeNewRoman Nerd Font Propo", {weight="Medium", stretch="Normal", style="Normal"})
config.use_ime = true
config.window_background_opacity = 0.85
config.window_decorations = "RESIZE"
config.enable_tab_bar = false
config.enable_wayland = false

return config
