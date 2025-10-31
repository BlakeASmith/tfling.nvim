local M = {}

local window_ops = require("tfling.window_ops")

--- Find a terminal instance from the current window/buffer
--- @param active_instances table
--- @param terms table
--- @return table|nil terminal instance
local function find_term_instance(active_instances, terms)
	local term_instance = active_instances[vim.api.nvim_get_current_win()]

	local current_buf = vim.api.nvim_get_current_buf()
	if not term_instance then
		for win_id, instance in pairs(active_instances) do
			if instance.bufnr == current_buf then
				term_instance = instance
				break
			end
		end
	end

	if not term_instance and vim.bo[current_buf].filetype == "tfling" then
		for name, instance in pairs(terms) do
			if instance.bufnr == current_buf then
				term_instance = instance
				break
			end
		end
	end

	return term_instance
end

--- Parse resize arguments
--- @param args string command arguments
--- @return table options table with width and/or height
local function parse_resize_args(args)
	local options = {}
	for part in (args or ""):gmatch("%S+") do
		local key, value = part:match("^(%w+)=(.+)$")
		if key == "width" or key == "w" then
			options.width = value
		elseif key == "height" or key == "h" then
			options.height = value
		elseif part:match("^%d") or part:match("%%$") or part:match("^%+") then
			if not options.width then
				options.width = part
			else
				options.height = part
			end
		end
	end
	return options
end

--- Parse reposition arguments
--- @param args string command arguments
--- @return table options table with position, row, and/or col
local function parse_reposition_args(args)
	local options = {}
	for part in (args or ""):gmatch("%S+") do
		local key, value = part:match("^(%w+)=(.+)$")
		if key == "position" or key == "p" then
			options.position = value
		elseif key == "row" or key == "r" then
			options.row = value
		elseif key == "col" or key == "c" then
			options.col = value
		elseif part:match("^split%-") or part:match("^(center|top%-|bottom%-|left%-|right%-)") then
			options.position = part
		end
	end
	return options
end

--- Create resize command handler
--- @param active_instances table
--- @param terms table
--- @return function
function M.create_resize_command(active_instances, terms)
	return function(opts)
		local term_instance = find_term_instance(active_instances, terms)
		if not term_instance or not term_instance.win_id then
			vim.notify("No terminal found in current window", vim.log.levels.WARN)
			return
		end

		local options = parse_resize_args(opts.args)
		if vim.tbl_isempty(options) then
			vim.notify("Usage: TFlingResizeCurrent [width] [height] or width=<val> height=<val>", vim.log.levels.INFO)
			return
		end

		window_ops.resize(term_instance.win_id, options)
	end
end

--- Create reposition command handler
--- @param active_instances table
--- @param terms table
--- @return function
function M.create_reposition_command(active_instances, terms)
	return function(opts)
		local term_instance = find_term_instance(active_instances, terms)
		if not term_instance or not term_instance.win_id then
			vim.notify("No terminal found in current window", vim.log.levels.WARN)
			return
		end

		local options = parse_reposition_args(opts.args)
		if vim.tbl_isempty(options) then
			vim.notify("Usage: TermRepositionCurrent [position] or position=<pos> [row=<val>] [col=<val>]", vim.log.levels.INFO)
			return
		end

		window_ops.reposition(term_instance.win_id, options, term_instance)
	end
end

return M
