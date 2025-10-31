local M = {}

--- Get the currently selected text in visual mode
--- Returns nil if not in visual mode or if no valid selection exists
--- @return string|nil selected text or nil if not in visual mode
function M.get_selected_text()
	-- Check if we're currently in visual mode using nvim_get_mode()
	local mode_info = vim.api.nvim_get_mode()
	local current_mode = mode_info.mode

	-- Check if we're in any visual mode (v, V, or Ctrl+V)
	if not string.match(current_mode, "^[vV]") and current_mode ~= "\22" then
		-- Not in visual mode, do NOT capture anything
		return nil
	end

	-- We ARE in visual mode, so force normal mode and capture
	vim.cmd("normal! \27") -- Send Escape to exit visual mode

	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	if start_pos[2] <= 0 or end_pos[2] <= 0 then
		return nil
	end

	local lines = vim.api.nvim_buf_get_lines(0, start_pos[2] - 1, end_pos[2], false)
	if #lines == 0 then
		return nil
	end

	-- Extract the selection based on positions
	local result = {}
	for i, line in ipairs(lines) do
		local start_col = start_pos[3]
		local end_col = end_pos[3]

		if i == 1 and i == #lines then
			-- Single line selection
			table.insert(result, string.sub(line, start_col, end_col))
		elseif i == 1 then
			-- First line of multi-line selection
			table.insert(result, string.sub(line, start_col))
		elseif i == #lines then
			-- Last line of multi-line selection
			table.insert(result, string.sub(line, 1, end_col))
		else
			-- Middle lines
			table.insert(result, line)
		end
	end

	return table.concat(result, "\n")
end

--- Get the path to the tfling tmux config file
--- @return string
function M.get_tmux_config_path()
	-- Get the directory of the current script (this util.lua file)
	local script_path = debug.getinfo(1, "S").source:sub(2) -- Remove the @ prefix
	local script_dir = vim.fn.fnamemodify(script_path, ":h")
	
	-- Navigate up from lua/tfling/util.lua to the plugin root
	-- script_dir is lua/tfling/, so go up two levels to get plugin root
	local plugin_root = vim.fn.fnamemodify(script_dir, ":h:h")
	local config_path = plugin_root .. "/resources/tfling.tmux.conf"
	
	-- Verify the config file exists
	if vim.fn.filereadable(config_path) == 0 then
		vim.notify(
			"tfling.nvim: tmux config file not found at " .. config_path,
			vim.log.levels.ERROR
		)
	end
	
	return config_path
end

return M
