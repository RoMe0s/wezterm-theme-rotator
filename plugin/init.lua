math.randomseed(os.time() + os.clock() * 1000)

-- WezTerm Theme Rotator Plugin
local wezterm = require('wezterm')

local ThemeRotator = {}

local state = {
    themes = {},
    current_index = 1,
    default_theme = nil,
    on_theme_change = nil,
}

-----------------------------------------------------------
-- Core Functions
-----------------------------------------------------------

local function is_dark_theme(scheme)
    local bg = scheme.background
    if not bg then return true end
    bg = bg:gsub('#', '')
    local r = tonumber(bg:sub(1, 2), 16) or 0
    local g = tonumber(bg:sub(3, 4), 16) or 0
    local b = tonumber(bg:sub(5, 6), 16) or 0
    local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    return luminance < 0.5
end

local function build_theme_list(filter)
    local schemes = wezterm.color.get_builtin_schemes()
    local themes = {}

    for name, scheme in pairs(schemes) do
        if filter == 'dark' and is_dark_theme(scheme) then
            table.insert(themes, name)
        elseif filter == 'light' and not is_dark_theme(scheme) then
            table.insert(themes, name)
        elseif not filter then
            table.insert(themes, name)
        end
    end

    table.sort(themes)
    return themes
end

local function find_theme_index(theme_name)
    for i, name in ipairs(state.themes) do
        if name == theme_name then
            return i
        end
    end
    return 1
end

local function apply_theme(window, new_index, operation_name)
    state.current_index = new_index
    local theme_name = state.themes[state.current_index]

    window:set_config_overrides({ color_scheme = theme_name })

    if state.on_theme_change then
        state.on_theme_change(window, theme_name)
    end
end

-----------------------------------------------------------
-- Theme Operations
-----------------------------------------------------------

local function next_theme(window)
    local new_index = (state.current_index % #state.themes) + 1
    apply_theme(window, new_index, 'Next theme')
end

local function prev_theme(window)
    local new_index = state.current_index - 1
    if new_index < 1 then
        new_index = #state.themes
    end
    apply_theme(window, new_index, 'Previous theme')
end

local function random_theme(window)
    local current_theme_index = state.current_index
    local new_index = current_theme_index

    while new_index == current_theme_index do
        new_index = math.random(1, #state.themes)
    end

    apply_theme(window, new_index, 'Random theme')
end

local function default_theme(window)
    if state.default_theme then
        local default_index = find_theme_index(state.default_theme)
        apply_theme(window, default_index, 'Default theme')
    else
        apply_theme(window, 1, 'First theme')
    end
end

-----------------------------------------------------------
-- Configuration
-----------------------------------------------------------

local function setup_key_bindings(options)
    local keys = {}

    table.insert(keys, {
        key = options.next_theme_key or 'n',
        mods = options.next_theme_mods or 'SUPER|SHIFT',
        action = wezterm.action_callback(function(window, pane)
            next_theme(window)
        end),
    })

    table.insert(keys, {
        key = options.prev_theme_key or 'p',
        mods = options.prev_theme_mods or 'SUPER|SHIFT',
        action = wezterm.action_callback(function(window, pane)
            prev_theme(window)
        end),
    })

    table.insert(keys, {
        key = options.random_theme_key or 'r',
        mods = options.random_theme_mods or 'SUPER|SHIFT',
        action = wezterm.action_callback(function(window, pane)
            random_theme(window)
        end),
    })

    table.insert(keys, {
        key = options.default_theme_key or 'd',
        mods = options.default_theme_mods or 'SUPER|SHIFT',
        action = wezterm.action_callback(function(window, pane)
            default_theme(window)
        end),
    })

    return keys
end

local function initialize_theme_state(config, options)
    state.themes = build_theme_list(options.filter)

    state.default_theme = config.color_scheme

    if config.color_scheme then
        state.current_index = find_theme_index(config.color_scheme)
    else
        state.current_index = 1
        config.color_scheme = state.themes[state.current_index]
        state.default_theme = config.color_scheme
    end
end

-----------------------------------------------------------
-- Public API
-----------------------------------------------------------

function ThemeRotator.apply_to_config(config, options)
    options = options or {}
    state.on_theme_change = options.on_theme_change

    initialize_theme_state(config, options)

    local keys = setup_key_bindings(options)
    config.keys = config.keys or {}
    for _, key_entry in ipairs(keys) do
        table.insert(config.keys, key_entry)
    end

    return config
end

return ThemeRotator
