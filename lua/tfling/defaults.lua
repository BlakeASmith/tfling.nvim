local M = {}

-- Default window configurations
local FloatingDefaults = {
	position = "top-center",
	width = "80%",
	height = "80%",
	margin = "5%",
}

local SplitDefaults = {
	width = "30%",  -- Used for split-left/split-right
	height = "40%", -- Used for split-top/split-bottom
}

--- Check if position indicates a split window
--- @param position string position value
--- @return boolean true if position is a split
local function is_split_position(position)
	return position and position:match("^split%-") ~= nil
end

--- Check if split position is horizontal (uses height)
--- @param position string position value like "split-top" or "split-bottom"
--- @return boolean true if horizontal split
local function is_horizontal_split(position)
	return position == "split-top" or position == "split-bottom"
end

--- Apply default values to a table, merging provided values with defaults
--- @param tbl table table to apply defaults to
--- @param defaults table default values
--- @return table merged table with defaults applied
local function ApplyDefaults(tbl, defaults)
	local applied = {}
	for key, value in pairs(tbl) do
		applied[key] = value or defaults[key]
	end

	-- There may be keys in defaults which are not in tbl
	for key, value in pairs(defaults) do
		if applied[key] == nil then
			applied[key] = value
		end
	end
	return applied
end

--- Expand size field to width/height based on window type
--- @param opts table window configuration
--- @return table window configuration with size expanded
local function expand_size(opts)
	if not opts.size then
		return opts
	end

	-- Validate: size and width/height are mutually exclusive
	if opts.width or opts.height then
		vim.notify(
			"tfling: 'size' and 'width'/'height' are mutually exclusive. 'size' will override 'width'/'height'.",
			vim.log.levels.WARN
		)
		-- Clear width/height when size is present
		opts.width = nil
		opts.height = nil
	end

	if is_split_position(opts.position or "center") then
		-- For splits: size becomes width for vertical splits, height for horizontal splits
		if is_horizontal_split(opts.position) then
			opts.height = opts.size
		else
			opts.width = opts.size
		end
	else
		-- For floating: size becomes both width and height
		opts.width = opts.size
		opts.height = opts.size
	end

	-- Remove size field after expansion
	opts.size = nil
	return opts
end

--- Apply default window configuration based on position
--- @param opts table window configuration with position field
--- @return table window configuration with defaults applied
function M.apply_win_defaults(opts)
	-- Expand size field first if present
	opts = expand_size(opts)
	
	local position = opts.position or "center"
	
	if is_split_position(position) then
		-- For splits, apply split defaults
		local defaults = is_horizontal_split(position) and { height = SplitDefaults.height } or { width = SplitDefaults.width }
		opts.position = position
		return ApplyDefaults(opts, defaults)
	else
		-- For floating windows, apply floating defaults
		return ApplyDefaults(opts, FloatingDefaults)
	end
end

return M
