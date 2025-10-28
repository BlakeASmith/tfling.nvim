local M = {}
---
-- Internal helper to calculate pixel geometry for floating windows.
--
function M.floating(win_config)
	local width_str = win_config.width
	local height_str = win_config.height
	local margin_str = win_config.margin
	local position = win_config.position

	-- Calculate pixel values
	local width = math.floor(vim.o.columns * (tonumber((width_str:gsub("%%", ""))) / 100))
	local height = math.floor(vim.o.lines * (tonumber((height_str:gsub("%%", ""))) / 100))
	local margin = math.floor(math.min(vim.o.lines, vim.o.columns) * (tonumber((margin_str:gsub("%%", ""))) / 100))

	-- Ensure it's not larger than the screen
	width = math.min(width, vim.o.columns - 2)
	height = math.min(height, vim.o.lines - 2)

	-- Calculate position based on placement
	local row, col
	if position == "center" then
		row = math.floor((vim.o.lines - height) / 2)
		col = math.floor((vim.o.columns - width) / 2)
	elseif position == "top-left" then
		row = margin
		col = margin
	elseif position == "top-center" then
		row = margin
		col = math.floor((vim.o.columns - width) / 2)
	elseif position == "top-right" then
		row = margin
		col = vim.o.columns - width - margin
	elseif position == "bottom-left" then
		row = vim.o.lines - height - margin
		col = margin
	elseif position == "bottom-center" then
		row = vim.o.lines - height - margin
		col = math.floor((vim.o.columns - width) / 2)
	elseif position == "bottom-right" then
		row = vim.o.lines - height - margin
		col = vim.o.columns - width - margin
	elseif position == "left-center" then
		row = math.floor((vim.o.lines - height) / 2)
		col = margin
	elseif position == "right-center" then
		row = math.floor((vim.o.lines - height) / 2)
		col = vim.o.columns - width - margin
	else
		-- Default to center if invalid position
		row = math.floor((vim.o.lines - height) / 2)
		col = math.floor((vim.o.columns - width) / 2)
	end

	-- Return the full table for nvim_open_win
	return {
		relative = "editor",
		style = "minimal",
		width = width,
		height = height,
		row = row,
		col = col,
		border = "rounded",
	}
end

return M
