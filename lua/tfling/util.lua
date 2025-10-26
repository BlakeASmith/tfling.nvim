local M = {}

function M:get_selected_text()
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

return M
