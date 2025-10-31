local M = {}

-- Position constants
local POSITION = {
	CENTER = "center",
	TOP_LEFT = "top-left",
	TOP_CENTER = "top-center",
	TOP_RIGHT = "top-right",
	BOTTOM_LEFT = "bottom-left",
	BOTTOM_CENTER = "bottom-center",
	BOTTOM_RIGHT = "bottom-right",
	LEFT_CENTER = "left-center",
	RIGHT_CENTER = "right-center",
}

-- Window configuration constants
local WINDOW_STYLE = "minimal"
local WINDOW_RELATIVE = "editor"
local WINDOW_BORDER = "rounded"
local MIN_WINDOW_PADDING = 2

--- Calculate floating window geometry from configuration
--- @param win_config table window configuration with width, height, margin, and position
--- @return table nvim_open_win configuration table
function M.floating(win_config)
	-- Calculate pixel values
	local width = math.floor(vim.o.columns * (tonumber((win_config.width:gsub("%%", ""))) / 100))
	local height = math.floor(vim.o.lines * (tonumber((win_config.height:gsub("%%", ""))) / 100))
	local margin = math.floor(math.min(vim.o.lines, vim.o.columns) * (tonumber((win_config.margin:gsub("%%", ""))) / 100))

	-- Ensure it's not larger than the screen
	width = math.min(width, vim.o.columns - MIN_WINDOW_PADDING)
	height = math.min(height, vim.o.lines - MIN_WINDOW_PADDING)

	-- Calculate position based on placement
	local row, col
	local position = win_config.position
	if position == POSITION.CENTER then
		row = math.floor((vim.o.lines - height) / 2)
		col = math.floor((vim.o.columns - width) / 2)
	elseif position == POSITION.TOP_LEFT then
		row = margin
		col = margin
	elseif position == POSITION.TOP_CENTER then
		row = margin
		col = math.floor((vim.o.columns - width) / 2)
	elseif position == POSITION.TOP_RIGHT then
		row = margin
		col = vim.o.columns - width - margin
	elseif position == POSITION.BOTTOM_LEFT then
		row = vim.o.lines - height - margin
		col = margin
	elseif position == POSITION.BOTTOM_CENTER then
		row = vim.o.lines - height - margin
		col = math.floor((vim.o.columns - width) / 2)
	elseif position == POSITION.BOTTOM_RIGHT then
		row = vim.o.lines - height - margin
		col = vim.o.columns - width - margin
	elseif position == POSITION.LEFT_CENTER then
		row = math.floor((vim.o.lines - height) / 2)
		col = margin
	elseif position == POSITION.RIGHT_CENTER then
		row = math.floor((vim.o.lines - height) / 2)
		col = vim.o.columns - width - margin
	else
		-- Default to center if invalid position
		row = math.floor((vim.o.lines - height) / 2)
		col = math.floor((vim.o.columns - width) / 2)
	end

	-- Return the full table for nvim_open_win
	return {
		relative = WINDOW_RELATIVE,
		style = WINDOW_STYLE,
		width = width,
		height = height,
		row = row,
		col = col,
		border = WINDOW_BORDER,
	}
end

return M
