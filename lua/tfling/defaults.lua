local M = {}

-- Default window configurations
local FloatingDefaults = {
	type = "floating",
	height = "80%",
	width = "80%",
	position = "top-center",
	margin = "5%",
}

local VerticalSplitDefaults = {
	type = "split",
	size = "30%",
	direction = "right",
}

local HorizontalSplitDefaults = {
	type = "split",
	size = "40%",
	direction = "bottom",
}

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

--- Check if split direction is vertical (top/bottom)
--- @param opts table options with direction field
--- @return boolean true if direction is vertical
local function is_vertical(opts)
	return opts.direction == "bottom" or opts.direction == "top"
end

--- Apply default window configuration based on window type
--- @param opts termSplitWin | termFloatingWin window configuration
--- @return termSplitWin | termFloatingWin window configuration with defaults applied
function M.apply_win_defaults(opts)
	if opts.type == "floating" then
		return ApplyDefaults(opts, FloatingDefaults)
	elseif opts.type == "split" then
		if is_vertical(opts) then
			return ApplyDefaults(opts, VerticalSplitDefaults)
		else
			return ApplyDefaults(opts, HorizontalSplitDefaults)
		end
	else
		-- Default to floating if type is unknown
		return ApplyDefaults(opts, FloatingDefaults)
	end
end

return M
