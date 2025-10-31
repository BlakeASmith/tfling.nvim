local M = {}

local window_ops = require("tfling.window_ops")

--- Find a terminal instance from the current window/buffer
--- @param active_instances table
--- @param terms table
--- @return table|nil terminal instance
local function find_term_instance(active_instances, terms)
	local term_instance = active_instances[vim.api.nvim_get_current_win()]

	-- If not found by window, try to find by checking all active instances for matching buffer
	local current_buf = vim.api.nvim_get_current_buf()
	if not term_instance then
		for win_id, instance in pairs(active_instances) do
			if instance.bufnr == current_buf then
				term_instance = instance
				break
			end
		end
	end

	-- If still not found, check if current buffer is a terminal buffer
	if not term_instance and vim.bo[current_buf].filetype == "tfling" then
		-- Find the terminal instance by name
		for name, instance in pairs(terms) do
			if instance.bufnr == current_buf then
				term_instance = instance
				break
			end
		end
	end

	return term_instance
end

--- Create resize command handler
--- @param active_instances table
--- @param terms table
--- @return function
function M.create_resize_command(active_instances, terms)
	return function(opts)
		local term_instance = find_term_instance(active_instances, terms)

		if not term_instance then
			vim.notify("No terminal found in current window", vim.log.levels.WARN)
			return
		end

		-- Parse resize options from command arguments
		local resize_options = {}
		local width_match = opts.args:match("width=([^%s]+)")
		if width_match then
			resize_options.width = width_match
		end
		local height_match = opts.args:match("height=([^%s]+)")
		if height_match then
			resize_options.height = height_match
		end

		-- If no arguments provided, show usage
		if vim.tbl_isempty(resize_options) then
			vim.notify("Usage: termResizeCurrent width=<value> height=<value>", vim.log.levels.INFO)
			vim.notify("Examples:", vim.log.levels.INFO)
			vim.notify("  termResizeCurrent width=+5%%", vim.log.levels.INFO)
			vim.notify("  termResizeCurrent height=50%%", vim.log.levels.INFO)
			vim.notify("  termResizeCurrent width=80 height=30", vim.log.levels.INFO)
			return
		end

		window_ops.resize(term_instance.win_id, resize_options)
	end
end

--- Create reposition command handler
--- @param active_instances table
--- @param terms table
--- @return function
function M.create_reposition_command(active_instances, terms)
	return function(opts)
		local term_instance = find_term_instance(active_instances, terms)

		if not term_instance then
			vim.notify("No terminal found in current window", vim.log.levels.WARN)
			return
		end

		-- Parse reposition options from command arguments
		local reposition_options = {}
		local position_match = opts.args:match("position=([^%s]+)")
		if position_match then
			reposition_options.position = position_match
		end
		local row_match = opts.args:match("row=([^%s]+)")
		if row_match then
			reposition_options.row = row_match
		end
		local col_match = opts.args:match("col=([^%s]+)")
		if col_match then
			reposition_options.col = col_match
		end

		-- If no arguments provided, show usage
		if vim.tbl_isempty(reposition_options) then
			vim.notify(
				"Usage: termRepositionCurrent [position=<pos>] [row=<value>] [col=<value>]",
				vim.log.levels.INFO
			)
			vim.notify("Examples:", vim.log.levels.INFO)
			vim.notify("  termRepositionCurrent position=top-left", vim.log.levels.INFO)
			vim.notify("  termRepositionCurrent position=split-bottom", vim.log.levels.INFO)
			vim.notify("  termRepositionCurrent row=+10 col=+20", vim.log.levels.INFO)
			vim.notify("  termRepositionCurrent row=50% col=50%", vim.log.levels.INFO)
			return
		end

		window_ops.reposition(term_instance.win_id, reposition_options, term_instance)
	end
end

return M
