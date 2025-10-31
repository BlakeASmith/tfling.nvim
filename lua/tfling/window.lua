local M = {}

local Window = {}
Window.__index = Window
local active_windows = {}

local defaults = require("tfling.defaults")
local geometry = require("tfling.geometry")

---
-- Internal helper to calculate pixel geometry for floating windows.
--
function Window:_calculate_floating_geometry(win_config)
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

---
-- Create a new Window instance
-- @param config table with bufnr or buffer creation options
-- @return Window instance
function M.new(config)
	local instance = setmetatable({}, Window)
	instance.bufnr = config.bufnr or nil
	instance.win_id = nil
	instance.name = config.name or nil
	instance.create_buffer_fn = config.create_buffer_fn or nil -- Optional function to create buffer
	return instance
end

function Window:toggle(opts)
	if opts == nil then
		self:hide()
		return
	end
	if opts and opts.win then
		local win_config = defaults.apply_win_defaults(opts.win)
		opts.win = win_config
	end
	if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
		if opts.win.type == "floating" then
			local final_win_opts = geometry.floating(opts.win)
			vim.api.nvim_win_set_config(self.win_id, final_win_opts)
			vim.api.nvim_set_current_win(self.win_id)
		else
			-- For splits, just focus the existing window
			vim.api.nvim_set_current_win(self.win_id)
		end
	else
		self:open(opts)
	end
end

function Window:hide()
	if not (self.win_id and vim.api.nvim_win_is_valid(self.win_id)) then
		return
	end
	active_windows[self.win_id] = nil
	vim.api.nvim_win_close(self.win_id, true)
	self.win_id = nil
end

---
-- Opens the window with the buffer.
--
function Window:open(opts)
	local win_config = defaults.apply_win_defaults(opts.win)

	-- If window is valid, just focus it
	if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
		vim.api.nvim_set_current_win(self.win_id)
		return
	end

	-- If buffer exists, create window based on type
	if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
		if win_config.type == "floating" then
			local final_win_opts = geometry.floating(win_config)
			self.win_id = vim.api.nvim_open_win(self.bufnr, true, final_win_opts)
		else
			self:_create_split_window(win_config)
		end
		active_windows[self.win_id] = self
		self:setup_win_options()
		return
	end

	-- Create buffer if needed
	if not self.bufnr then
		if self.create_buffer_fn then
			self.bufnr = self.create_buffer_fn()
		else
			-- Default: create a new buffer
			self.bufnr = vim.api.nvim_create_buf(true, true)
			vim.bo[self.bufnr].bufhidden = "hide"
		end
	end

	if win_config.type == "floating" then
		local final_win_opts = geometry.floating(win_config)
		self.win_id = vim.api.nvim_open_win(self.bufnr, true, final_win_opts)
	else
		self:_create_split_window(win_config)
	end
	active_windows[self.win_id] = self
	self:setup_win_options()
end

function Window:_create_split_window(win_config)
	local size_str = win_config.size
	local size_percent = tonumber((size_str:gsub("%%", "")))
	local actual_size

	if win_config.direction == "top" or win_config.direction == "bottom" then
		-- Horizontal split - calculate percentage of total lines
		actual_size = math.floor(vim.o.lines * (size_percent / 100))
		if win_config.direction == "top" then
			vim.cmd("topleft split")
		else
			vim.cmd("botright split")
		end
		vim.cmd("resize " .. actual_size)
	elseif win_config.direction == "left" or win_config.direction == "right" then
		-- Vertical split - calculate percentage of total columns
		actual_size = math.floor(vim.o.columns * (size_percent / 100))
		if win_config.direction == "left" then
			vim.cmd("topleft vsplit")
		else
			vim.cmd("botright vsplit")
		end
		vim.cmd("vertical resize " .. actual_size)
	end

	-- Get the current window ID after creating the split
	self.win_id = vim.api.nvim_get_current_win()

	-- Set the buffer to the window
	vim.api.nvim_win_set_buf(self.win_id, self.bufnr)
end

function Window:setup_win_options()
	local win_id = self.win_id
	local current_config = vim.api.nvim_win_get_config(win_id)
	if current_config.relative == "editor" then
		vim.wo[win_id].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"
	end
	vim.wo[win_id].relativenumber = false
	vim.wo[win_id].number = false
	vim.wo[win_id].signcolumn = "no"
end

---
-- Resize the window
-- @param options table with width/height options
function Window:resize(options)
	if not self.win_id or not vim.api.nvim_win_is_valid(self.win_id) then
		return
	end

	local win_id = self.win_id
	local current_config = vim.api.nvim_win_get_config(win_id)

	-- Handle floating windows
	if current_config.relative == "editor" then
		local new_config = vim.tbl_deep_extend("force", {}, current_config)

		if options.width then
			if type(options.width) == "string" then
				if options.width:match("^%+%d+%%$") then
					-- Relative increase: "+5%"
					local percent = tonumber(options.width:match("%d+"))
					new_config.width = current_config.width
						+ math.floor(current_config.width * percent / 100)
				elseif options.width:match("^%d+%%$") then
					-- Absolute percentage: "50%"
					local percent = tonumber(options.width:match("%d+"))
					new_config.width = math.floor(vim.o.columns * percent / 100)
				else
					-- Absolute value
					new_config.width = tonumber(options.width)
				end
			else
				new_config.width = options.width
			end
		end

		if options.height then
			if type(options.height) == "string" then
				if options.height:match("^%+%d+%%$") then
					-- Relative increase: "+5%"
					local percent = tonumber(options.height:match("%d+"))
					new_config.height = current_config.height
						+ math.floor(current_config.height * percent / 100)
				elseif options.height:match("^%d+%%$") then
					-- Absolute percentage: "50%"
					local percent = tonumber(options.height:match("%d+"))
					new_config.height = math.floor(vim.o.lines * percent / 100)
				else
					-- Absolute value
					new_config.height = tonumber(options.height)
				end
			else
				new_config.height = options.height
			end
		end

		-- Ensure window stays within screen bounds
		new_config.width = math.min(new_config.width, vim.o.columns - 2)
		new_config.height = math.min(new_config.height, vim.o.lines - 2)

		vim.api.nvim_win_set_config(win_id, new_config)

		-- Handle split windows
	else
		if options.height then
			local new_height
			if type(options.height) == "string" then
				if options.height:match("^%+%d+%%$") then
					-- Relative increase: "+5%"
					local percent = tonumber(options.height:match("%d+"))
					local current_height = vim.api.nvim_win_get_height(win_id)
					new_height = current_height + math.floor(current_height * percent / 100)
				elseif options.height:match("^%d+%%$") then
					-- Absolute percentage: "50%"
					local percent = tonumber(options.height:match("%d+"))
					new_height = math.floor(vim.o.lines * percent / 100)
				else
					-- Absolute value
					new_height = tonumber(options.height)
				end
			else
				new_height = options.height
			end
			vim.api.nvim_win_set_height(win_id, new_height)
		end

		if options.width then
			local new_width
			if type(options.width) == "string" then
				if options.width:match("^%+%d+%%$") then
					-- Relative increase: "+5%"
					local percent = tonumber(options.width:match("%d+"))
					local current_width = vim.api.nvim_win_get_width(win_id)
					new_width = current_width + math.floor(current_width * percent / 100)
				elseif options.width:match("^%d+%%$") then
					-- Absolute percentage: "50%"
					local percent = tonumber(options.width:match("%d+"))
					new_width = math.floor(vim.o.columns * percent / 100)
				else
					-- Absolute value
					new_width = tonumber(options.width)
				end
			else
				new_width = options.width
			end
			vim.api.nvim_win_set_width(win_id, new_width)
		end
	end
end

---
-- Reposition the window
-- @param options table with position/row/col/direction options
function Window:reposition(options)
	if not self.win_id or not vim.api.nvim_win_is_valid(self.win_id) then
		return
	end

	local win_id = self.win_id
	local current_config = vim.api.nvim_win_get_config(win_id)

	-- Handle floating windows
	if current_config.relative == "editor" then
		local new_config = vim.tbl_deep_extend("force", {}, current_config)

		-- Handle position-based repositioning
		if options.position then
			local win_config = {
				type = "floating",
				position = options.position,
				width = tostring(math.floor(current_config.width * 100 / vim.o.columns)) .. "%",
				height = tostring(math.floor(current_config.height * 100 / vim.o.lines)) .. "%",
				margin = "2%",
			}
			local final_win_opts = self:_calculate_floating_geometry(win_config)
			new_config.row = final_win_opts.row
			new_config.col = final_win_opts.col
		end

		-- Handle row-based repositioning
		if options.row then
			if type(options.row) == "string" then
				if options.row:match("^%+%d+$") then
					-- Relative increase: "+10"
					local offset = tonumber(options.row:match("%d+"))
					new_config.row = current_config.row + offset
				elseif options.row:match("^%d+%%$") then
					-- Absolute percentage: "50%"
					local percent = tonumber(options.row:match("%d+"))
					new_config.row = math.floor(vim.o.lines * percent / 100)
				else
					-- Absolute value
					new_config.row = tonumber(options.row)
				end
			else
				new_config.row = options.row
			end
		end

		-- Handle column-based repositioning
		if options.col then
			if type(options.col) == "string" then
				if options.col:match("^%+%d+$") then
					-- Relative increase: "+10"
					local offset = tonumber(options.col:match("%d+"))
					new_config.col = current_config.col + offset
				elseif options.col:match("^%d+%%$") then
					-- Absolute percentage: "50%"
					local percent = tonumber(options.col:match("%d+"))
					new_config.col = math.floor(vim.o.columns * percent / 100)
				else
					-- Absolute value
					new_config.col = tonumber(options.col)
				end
			else
				new_config.col = options.col
			end
		end

		-- Ensure window stays within screen bounds
		new_config.row = math.max(0, math.min(new_config.row, vim.o.lines - new_config.height))
		new_config.col = math.max(0, math.min(new_config.col, vim.o.columns - new_config.width))

		vim.api.nvim_win_set_config(win_id, new_config)

		-- Handle split windows
	else
		if options.direction then
			-- For split windows, we need to recreate the window in the new direction
			local current_height = vim.api.nvim_win_get_height(win_id)
			local current_width = vim.api.nvim_win_get_width(win_id)
			local size_percent

			if options.direction == "top" or options.direction == "bottom" then
				size_percent = math.floor(current_height * 100 / vim.o.lines)
			else
				size_percent = math.floor(current_width * 100 / vim.o.columns)
			end

			-- Close current window
			vim.api.nvim_win_close(win_id, true)

			-- Create new split in the specified direction
			local win_config = {
				type = "split",
				direction = options.direction,
				size = tostring(size_percent) .. "%",
			}
			self:_create_split_window(win_config)
			vim.api.nvim_win_set_buf(self.win_id, self.bufnr)
			self:setup_win_options()
		end
	end
end

---
-- Get window instance by window ID
-- @param win_id number
-- @return Window instance or nil
function M.get_window(win_id)
	return active_windows[win_id]
end

---
-- Get window instance by buffer number
-- @param bufnr number
-- @return Window instance or nil
function M.get_window_by_buffer(bufnr)
	for win_id, window in pairs(active_windows) do
		if window.bufnr == bufnr and vim.api.nvim_win_is_valid(win_id) then
			return window
		end
	end
	return nil
end

---
-- Find window instance for current window or buffer
-- @return Window instance or nil
function M.find_current_window()
	local current_win = vim.api.nvim_get_current_win()
	local window = active_windows[current_win]
	if window then
		return window
	end

	-- Try to find by buffer
	local current_buf = vim.api.nvim_get_current_buf()
	return M.get_window_by_buffer(current_buf)
end

return M
