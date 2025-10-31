local M = {}

local geometry = require("tfling.geometry")

--- Check if position indicates a split window
--- @param position string position value
--- @return boolean true if position is a split
local function is_split_position(position)
	return position and position:match("^split%-") ~= nil
end

--- Extract split direction from position
--- @param position string position like "split-bottom"
--- @return string direction like "bottom"
local function get_split_direction(position)
	if not is_split_position(position) then
		return nil
	end
	return position:gsub("^split%-", "")
end

--- Parse a size string (number, percentage, or relative)
--- @param size_str number|string size as number, percentage string ("50%"), or relative ("+5%")
--- @param base number base value for percentage calculations
--- @param current? number current value for relative calculations
--- @return number parsed size value
local function parse_size(size_str, base, current)
	if type(size_str) == "string" then
		if size_str:match("^%+%d+%%$") then
			-- Relative increase: "+5%"
			return current and (current + math.floor(current * tonumber(size_str:match("%d+")) / 100)) or base
		elseif size_str:match("^%d+%%$") then
			-- Absolute percentage: "50%"
			return math.floor(base * tonumber(size_str:match("%d+")) / 100)
		else
			-- Absolute value
			return tonumber(size_str)
		end
	else
		return size_str
	end
end

--- Parse a position string (number, percentage, or relative)
--- @param pos_str number|string
--- @param base number base value for percentage calculations
--- @param current? number current value for relative calculations
--- @return number
local function parse_position(pos_str, base, current)
	if type(pos_str) == "string" then
		if pos_str:match("^%+%d+$") then
			-- Relative increase: "+10"
			return current and (current + tonumber(pos_str:match("%d+"))) or base
		elseif pos_str:match("^%d+%%$") then
			-- Absolute percentage: "50%"
			return math.floor(base * tonumber(pos_str:match("%d+")) / 100)
		else
			-- Absolute value
			return tonumber(pos_str)
		end
	else
		return pos_str
	end
end

--- Resize a floating window
--- @param win_id number
--- @param options table with width and/or height
local function resize_floating(win_id, options)
	local current_config = vim.api.nvim_win_get_config(win_id)
	local new_config = vim.tbl_deep_extend("force", {}, current_config)

	if options.width then
		new_config.width = parse_size(options.width, vim.o.columns, current_config.width)
	end

	if options.height then
		new_config.height = parse_size(options.height, vim.o.lines, current_config.height)
	end

	-- Ensure window stays within screen bounds
	new_config.width = math.min(new_config.width, vim.o.columns - 2)
	new_config.height = math.min(new_config.height, vim.o.lines - 2)

	vim.api.nvim_win_set_config(win_id, new_config)
end

--- Resize a split window
--- @param win_id number
--- @param options table with width and/or height
local function resize_split(win_id, options)
	if options.height then
		vim.api.nvim_win_set_height(win_id, parse_size(options.height, vim.o.lines, vim.api.nvim_win_get_height(win_id)))
	end

	if options.width then
		vim.api.nvim_win_set_width(win_id, parse_size(options.width, vim.o.columns, vim.api.nvim_win_get_width(win_id)))
	end
end

--- Resize a terminal window
--- @param win_id number
--- @param options table with width and/or height
function M.resize(win_id, options)
	if vim.api.nvim_win_get_config(win_id).relative == "editor" then
		resize_floating(win_id, options)
	else
		resize_split(win_id, options)
	end
end

--- Reposition a floating window
--- @param win_id number
--- @param options table with position, row, and/or col
--- @param term_instance? table terminal instance (for position-based repositioning)
local function reposition_floating(win_id, options, term_instance)
	local current_config = vim.api.nvim_win_get_config(win_id)
	local new_config = vim.tbl_deep_extend("force", {}, current_config)

	-- Handle position-based repositioning
	if options.position and term_instance then
		local final_win_opts = geometry.floating({
			position = options.position,
			width = tostring(math.floor(current_config.width * 100 / vim.o.columns)) .. "%",
			height = tostring(math.floor(current_config.height * 100 / vim.o.lines)) .. "%",
			margin = "2%",
		})
		new_config.row = final_win_opts.row
		new_config.col = final_win_opts.col
	end

	-- Handle row-based repositioning
	if options.row then
		new_config.row = parse_position(options.row, vim.o.lines, current_config.row)
	end

	-- Handle column-based repositioning
	if options.col then
		new_config.col = parse_position(options.col, vim.o.columns, current_config.col)
	end

	-- Ensure window stays within screen bounds
	new_config.row = math.max(0, math.min(new_config.row, vim.o.lines - new_config.height))
	new_config.col = math.max(0, math.min(new_config.col, vim.o.columns - new_config.width))

	vim.api.nvim_win_set_config(win_id, new_config)
end

--- Reposition a split window
--- @param win_id number
--- @param options table with position
--- @param term_instance table terminal instance
local function reposition_split(win_id, options, term_instance)
	if options.position and is_split_position(options.position) then
		-- For split windows, we need to recreate the window in the new direction
		local direction = get_split_direction(options.position)
		local is_horizontal = direction == "top" or direction == "bottom"
		
		local win_config = {
			position = options.position,
		}
		
		if is_horizontal then
			win_config.height = tostring(math.floor(vim.api.nvim_win_get_height(win_id) * 100 / vim.o.lines)) .. "%"
		else
			win_config.width = tostring(math.floor(vim.api.nvim_win_get_width(win_id) * 100 / vim.o.columns)) .. "%"
		end

		-- Close current window
		vim.api.nvim_win_close(win_id, true)

		-- Create new split in the specified direction
		term_instance:_create_split_window(win_config)
		vim.api.nvim_win_set_buf(term_instance.win_id, term_instance.bufnr)
		term_instance:setup_win_options()
	end
end

--- Reposition a terminal window
--- @param win_id number
--- @param options table with position, row, and/or col
--- @param term_instance table terminal instance
function M.reposition(win_id, options, term_instance)
	if vim.api.nvim_win_get_config(win_id).relative == "editor" then
		reposition_floating(win_id, options, term_instance)
	else
		reposition_split(win_id, options, term_instance)
	end
end

return M
