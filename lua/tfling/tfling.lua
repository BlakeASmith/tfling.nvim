-- File: lua/floating_term.lua

local M = {}

local Terminal = {}
Terminal.__index = Terminal
local active_instances = {}

local util = require("tfling.util")
local get_selected_text = util.get_selected_text
local defaults = require("tfling.defaults")
local geometry = require("tfling.geometry")
local window_manager = require("tfling.window")

---
-- Internal helper to calculate pixel geometry for floating windows.
--
function Terminal:_calculate_floating_geometry(win_config)
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

function New(config)
	if not config.cmd then
		vim.notify("FloatingTerm:new() requires 'cmd'", vim.log.levels.ERROR)
		return
	end

	local instance = setmetatable({}, Terminal)
	instance.cmd = config.cmd
	instance.win_opts = config.win_opts or {} -- Legacy support
	instance.bufnr = nil
	instance.win_id = nil
	instance.job_id = nil
	return instance
end

function Terminal:toggle(opts)
	if opts == nil then
		self:hide()
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

function Terminal:hide()
	if not (self.win_id and vim.api.nvim_win_is_valid(self.win_id)) then
		return
	end
	active_instances[self.win_id] = nil
	vim.api.nvim_win_close(self.win_id, true)
	self.win_id = nil
end

---
-- Opens the terminal window.
--
function Terminal:open(opts)
	local win_config = defaults.apply_win_defaults(opts.win)

	-- 2. If window is valid, just focus it
	if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
		vim.api.nvim_set_current_win(self.win_id)
		return
	end

	-- 3. If buffer exists, create window based on type
	if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
		if win_config.type == "floating" then
			local final_win_opts = geometry.floating(win_config)
			self.win_id = vim.api.nvim_open_win(self.bufnr, true, final_win_opts)
		else
			self:_create_split_window(win_config)
		end
		active_instances[self.win_id] = self
		self:setup_win_options()
		vim.cmd("startinsert")
		return
	end

	-- 4. If new, create everything
	self.bufnr = vim.api.nvim_create_buf(true, true)
	vim.bo[self.bufnr].bufhidden = "hide"
	vim.bo[self.bufnr].filetype = "tfling"

	if win_config.type == "floating" then
		local final_win_opts = geometry.floating(win_config)
		self.win_id = vim.api.nvim_open_win(self.bufnr, true, final_win_opts)
	else
		self:_create_split_window(win_config)
	end
	active_instances[self.win_id] = self
	self:setup_win_options()

	local on_exit = vim.schedule_wrap(function()
		if active_instances[self.win_id] then
			active_instances[self.win_id] = nil
		end
		self.bufnr = nil
		self.win_id = nil
		self.job_id = nil
	end)

	vim.api.nvim_win_call(self.win_id, function()
		self.job_id = vim.fn.termopen(self.cmd, { on_exit = on_exit })
		vim.cmd("startinsert")
	end)
end

function Terminal:_create_split_window(win_config)
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

	-- Set the buffer to the terminal buffer
	vim.api.nvim_win_set_buf(self.win_id, self.bufnr)
end

function Terminal:setup_win_options()
	local win_id = self.win_id
	if self.win_config and self.win_config.type == "floating" then
		vim.wo[win_id].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"
	end
	vim.wo[win_id].relativenumber = false
	vim.wo[win_id].number = false
	vim.wo[win_id].signcolumn = "no"
end

function M.hide_current()
	local current_win = vim.api.nvim_get_current_win()
	local current_buf = vim.api.nvim_get_current_buf()
	
	-- Try to find window instance using window manager
	local window = window_manager.get_window(current_win)
	if not window then
		window = window_manager.get_window_by_buffer(current_buf)
	end
	
	-- Fallback: try to find terminal instance
	if window then
		window:hide()
	else
		local term_instance = active_instances[current_win]
		if term_instance then
			term_instance:hide()
		else
			-- Try to find by buffer
			for win_id, instance in pairs(active_instances) do
				if instance.bufnr == current_buf then
					instance:hide()
					return
				end
			end
			vim.notify("No tfling-managed window found in current window", vim.log.levels.WARN)
		end
	end
end

local terms = {}
local buffers = {}

--- @class termResizeOptions
--- @field width? number|string width as number, percentage ("50%"), or relative ("+5%")
--- @field height? number|string height as number, percentage ("50%"), or relative ("+5%")

--- @class termRepositionOptions
--- @field position? "top-left" | "top-center" | "top-right" | "bottom-left" | "bottom-right" | "bottom-center" | "left-center" | "right-center" | "center" position for floating windows
--- @field row? number|string row position as number, percentage ("50%"), or relative ("+10")
--- @field col? number|string column position as number, percentage ("50%"), or relative ("+10")
--- @field direction? "top" | "bottom" | "left" | "right" direction for split windows

--- @class termWindowOps
--- @field resize fun(options: termResizeOptions) resize the terminal window
--- @field reposition fun(options: termRepositionOptions) reposition the terminal window

--- @class termTermDetails
--- @field job_id number the job ID (channel ID for nvim_chan_send)
--- @field bufnr number the buffer number
--- @field win_id number the window ID
--- @field name string the terminal name
--- @field cmd string the command being run
--- @field send function helper function to send commands to the terminal
--- @field win termWindowOps window manipulation functions
--- @field selected_text? string the text that was selected when triggered from visual mode

--- @class termFloatingWin
--- @field type "floating"
--- @field position? "top-left" | "top-center" | "top-right" | "bottom-left" | "bottom-right" | "bottom-center" | "left-center" | "right-center" position of floating window (defaults to "center")
--- @field width? string width as a percentage like "80%" (defaults to "80%")
--- @field height? string height as a percentage like "80%" (defaults to "80%")
--- @field margin? string margin as a percentage like "2%" (defaults to "2%")

--- @class termSplitWin
--- @field type "split"
--- @field direction string split direction: "top", "bottom", "left", "right"
--- @field size string size as a percentage like "30%"

--- @class termTerm
--- @field name? string the name (needs to be unique, defaults to cmd)
--- @field cmd string the command/program to run
--- @field tmux? boolean whether to use tmux for this terminal (defaults to false)
--- @field abduco? boolean whether to use abduco for this terminal (defaults to false)
--- @field win? termFloatingWin|termSplitWin window configuration (defaults to floating center)
--- @field width? string width as a percentage like "80%" (deprecated, use win.width)
--- @field height? string height as a percentage like "80%" (deprecated, use win.height)
--- @field send_delay? number delay in milliseconds before sending commands (defaults to global config)
--- @field setup? fun(details: termTermDetails) function to run on mount (receives termTermDetails table)

--- @param opts termTerm
function M.term(opts)
	if opts.setup == nil then
		opts.setup = function() end
	end

	if opts.win == nil then
		opts.win = {
			type = "floating",
		}
	end

	-- Set default name to cmd if not provided
	if opts.name == nil then
		opts.name = opts.cmd
	end

	-- Handle tmux-backed terminals
	local actual_cmd = opts.cmd
	local cmd_table = vim.split(opts.cmd, " ")
	local session_name = "tfling-" .. (opts.name or opts.cmd)
	local sessions = require("tfling.sessions")

	local provider = nil
	if opts.tmux then
		provider = sessions.tmux
	end
	if opts.abduco then
		provider = sessions.abduco
	end
	if provider ~= nil then
		actual_cmd = table.concat(provider.create_or_attach_cmd({ session_id = session_name, cmd = cmd_table }), " ")
	end

	-- Capture selected text BEFORE any buffer operations
	local captured_selected_text = get_selected_text()

	if terms[opts.name] == nil then
		terms[opts.name] = New({
			cmd = actual_cmd,
			win_opts = {}, -- Legacy support
		})
	end

	-- Apply defaults to win configuration
	local win_config = defaults.apply_win_defaults(opts.win)
	opts.win = win_config
	terms[opts.name]:toggle(opts)
	-- call setup function in autocommand
	local augroup_name = "tfling." .. opts.name .. ".config"
	vim.api.nvim_create_augroup(augroup_name, {
		-- reset each time we enter
		clear = true,
	})
	-- on terminal enter (the window opening)
	vim.api.nvim_create_autocmd("TermEnter", {
		group = augroup_name,
		-- only apply in the buffer created for this program
		buffer = terms[opts.name].bufnr,
		callback = function()
			-- Create a table with terminal details to pass to the callback
			local term_details = {
				job_id = terms[opts.name].job_id,
				bufnr = terms[opts.name].bufnr,
				win_id = terms[opts.name].win_id,
				name = opts.name,
				cmd = actual_cmd,
				selected_text = captured_selected_text, -- Use the captured text
				-- Helper function to send commands to this terminal
				send = function(command)
					local term_instance = terms[opts.name]
					if term_instance and term_instance.job_id then
						-- Use per-terminal send_delay if provided, otherwise fall back to global config
						local delay = opts.send_delay or Config.send_delay or 100
						vim.defer_fn(function()
							vim.api.nvim_chan_send(term_instance.job_id, command)
						end, delay)
					end
				end,
				-- Helper function to resize the terminal window
				win = {
					resize = function(options)
						local term_instance = terms[opts.name]
						if not term_instance or not term_instance.win_id then
							return
						end

						local win_id = term_instance.win_id
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
					end,
					reposition = function(options)
						local term_instance = terms[opts.name]
						if not term_instance or not term_instance.win_id then
							return
						end

						local win_id = term_instance.win_id
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
								local final_win_opts = term_instance:_calculate_floating_geometry(win_config)
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
								term_instance:_create_split_window(win_config)
								vim.api.nvim_win_set_buf(term_instance.win_id, term_instance.bufnr)
								term_instance:setup_win_options()
							end
						end
					end,
				},
			}
			Config.always(term_details)
			opts.setup(term_details)
		end,
	})
end

Config = {
	always = function(term) end,
	send_delay = 100, -- Default delay in milliseconds
}

--- @class SetupOpts
--- @field always? fun(termTermDetails) callback ran in all tfling buffers
--- @field send_delay? number delay in milliseconds before sending commands (default: 100)
---
function M.setup(opts)
	if opts.always ~= nil then
		Config.always = opts.always
	end
	if opts.send_delay ~= nil then
		Config.send_delay = opts.send_delay
	end
end

--- @class bufferFloatingWin
--- @field type "floating"
--- @field position? "top-left" | "top-center" | "top-right" | "bottom-left" | "bottom-right" | "bottom-center" | "left-center" | "right-center" | "center" position of floating window (defaults to "center")
--- @field width? string width as a percentage like "80%" (defaults to "80%")
--- @field height? string height as a percentage like "80%" (defaults to "80%")
--- @field margin? string margin as a percentage like "2%" (defaults to "2%")
---
--- @class bufferSplitWin
--- @field type "split"
--- @field direction string split direction: "top", "bottom", "left", "right"
--- @field size string size as a percentage like "30%"
---
--- @class bufferWindowOps
--- @field resize fun(options: termResizeOptions) resize the window
--- @field reposition fun(options: termRepositionOptions) reposition the window
---
--- @class bufferDetails
--- @field bufnr number the buffer number
--- @field win_id number the window ID
--- @field name string the buffer name
--- @field win bufferWindowOps window manipulation functions
--- @field selected_text? string the text that was selected when triggered from visual mode
---
--- @class bufferOpts
--- @field name string the name (needs to be unique)
--- @field bufnr? number existing buffer number to use (optional)
--- @field create_buffer_fn? fun(): number function that returns a buffer number (optional)
--- @field win? bufferFloatingWin|bufferSplitWin window configuration (defaults to floating center)
--- @field setup? fun(details: bufferDetails) function to run on mount (receives bufferDetails table)
---
--- Opens any buffer with positioning and resizing support
--- @param opts bufferOpts
function M.buffer(opts)
	if opts.name == nil then
		vim.notify("tfling.buffer() requires 'name'", vim.log.levels.ERROR)
		return
	end

	if opts.setup == nil then
		opts.setup = function() end
	end

	if opts.win == nil then
		opts.win = {
			type = "floating",
		}
	end

	-- Capture selected text BEFORE any buffer operations
	local captured_selected_text = get_selected_text()

	-- Get or create window instance
	if buffers[opts.name] == nil then
		buffers[opts.name] = window_manager.new({
			name = opts.name,
			bufnr = opts.bufnr,
			create_buffer_fn = opts.create_buffer_fn,
		})
	end

	-- Apply defaults to win configuration
	local win_config = defaults.apply_win_defaults(opts.win)
	opts.win = win_config
	buffers[opts.name]:toggle(opts)

	-- Create a table with buffer details to pass to the callback
	local buffer_details = {
		bufnr = buffers[opts.name].bufnr,
		win_id = buffers[opts.name].win_id,
		name = opts.name,
		selected_text = captured_selected_text,
		-- Helper functions for window manipulation
		win = {
			resize = function(options)
				local window = buffers[opts.name]
				if window then
					window:resize(options)
				end
			end,
			reposition = function(options)
				local window = buffers[opts.name]
				if window then
					window:reposition(options)
				end
			end,
		},
	}

	opts.setup(buffer_details)
end

vim.api.nvim_create_user_command("TFlingHideCurrent", M.hide_current, {})

vim.api.nvim_create_user_command("TFlingResizeCurrent", function(opts)
	local current_win = vim.api.nvim_get_current_win()
	local current_buf = vim.api.nvim_get_current_buf()
	
	-- Try to find window instance using window manager
	local window = window_manager.get_window(current_win)
	if not window then
		window = window_manager.get_window_by_buffer(current_buf)
	end
	
	-- Fallback: try to find terminal instance
	local term_instance = nil
	if not window then
		term_instance = active_instances[current_win]
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
	end

	if not window and not term_instance then
		vim.notify("No tfling-managed window found in current window", vim.log.levels.WARN)
		return
	end

	-- Parse resize options from command arguments
	local resize_options = {}

	-- Parse width argument
	local width_match = opts.args:match("width=([^%s]+)")
	if width_match then
		resize_options.width = width_match
	end

	-- Parse height argument
	local height_match = opts.args:match("height=([^%s]+)")
	if height_match then
		resize_options.height = height_match
	end

	-- If no arguments provided, show usage
	if vim.tbl_isempty(resize_options) then
		vim.notify("Usage: TFlingResizeCurrent width=<value> height=<value>", vim.log.levels.INFO)
		vim.notify("Examples:", vim.log.levels.INFO)
		vim.notify("  TFlingResizeCurrent width=+5%%", vim.log.levels.INFO)
		vim.notify("  TFlingResizeCurrent height=50%%", vim.log.levels.INFO)
		vim.notify("  TFlingResizeCurrent width=80 height=30", vim.log.levels.INFO)
		return
	end

	-- Use window manager if available, otherwise fall back to terminal resize logic
	if window then
		window:resize(resize_options)
	else
		-- Legacy terminal resize logic
		local function resize_window(options)
			local win_id = term_instance.win_id
			local current_config = vim.api.nvim_win_get_config(win_id)

			-- Handle floating windows
			if current_config.relative == "editor" then
				local new_config = vim.tbl_deep_extend("force", {}, current_config)

				if options.width then
					if type(options.width) == "string" then
						if options.width:match("^%+%d+%%$") then
							-- Relative increase: "+5%"
							local percent = tonumber(options.width:match("%d+"))
							new_config.width = current_config.width + math.floor(current_config.width * percent / 100)
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
							new_config.height = current_config.height + math.floor(current_config.height * percent / 100)
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

		resize_window(resize_options)
	end
end, {
	nargs = "?",
	complete = function()
		return {
			"width=+5%",
			"width=+10%",
			"width=50%",
			"width=80%",
			"height=+5%",
			"height=+10%",
			"height=50%",
			"height=80%",
		}
	end,
	desc = "Resize the current window (terminal or buffer)",
})

vim.api.nvim_create_user_command("TermRepositionCurrent", function(opts)
	local current_win = vim.api.nvim_get_current_win()
	local current_buf = vim.api.nvim_get_current_buf()
	
	-- Try to find window instance using window manager
	local window = window_manager.get_window(current_win)
	if not window then
		window = window_manager.get_window_by_buffer(current_buf)
	end
	
	-- Fallback: try to find terminal instance
	local term_instance = nil
	if not window then
		term_instance = active_instances[current_win]
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
	end

	if not window and not term_instance then
		vim.notify("No tfling-managed window found in current window", vim.log.levels.WARN)
		return
	end

	-- Parse reposition options from command arguments
	local reposition_options = {}

	-- Parse position argument
	local position_match = opts.args:match("position=([^%s]+)")
	if position_match then
		reposition_options.position = position_match
	end

	-- Parse row argument
	local row_match = opts.args:match("row=([^%s]+)")
	if row_match then
		reposition_options.row = row_match
	end

	-- Parse col argument
	local col_match = opts.args:match("col=([^%s]+)")
	if col_match then
		reposition_options.col = col_match
	end

	-- Parse direction argument
	local direction_match = opts.args:match("direction=([^%s]+)")
	if direction_match then
		reposition_options.direction = direction_match
	end

	-- If no arguments provided, show usage
	if vim.tbl_isempty(reposition_options) then
		vim.notify(
			"Usage: TermRepositionCurrent [position=<pos>] [row=<value>] [col=<value>] [direction=<dir>]",
			vim.log.levels.INFO
		)
		vim.notify("Examples:", vim.log.levels.INFO)
		vim.notify("  TermRepositionCurrent position=top-left", vim.log.levels.INFO)
		vim.notify("  TermRepositionCurrent row=+10 col=+20", vim.log.levels.INFO)
		vim.notify("  TermRepositionCurrent row=50% col=50%", vim.log.levels.INFO)
		vim.notify("  TermRepositionCurrent direction=top", vim.log.levels.INFO)
		return
	end

	-- Use window manager if available, otherwise fall back to terminal reposition logic
	if window then
		window:reposition(reposition_options)
	else
		-- Legacy terminal reposition logic
		local function reposition_window(options)
			local win_id = term_instance.win_id
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
					local final_win_opts = term_instance:_calculate_floating_geometry(win_config)
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
					term_instance:_create_split_window(win_config)
					vim.api.nvim_win_set_buf(term_instance.win_id, term_instance.bufnr)
					term_instance:setup_win_options()
				end
			end
		end

		reposition_window(reposition_options)
	end
end, {
	nargs = "?",
	complete = function()
		return {
			"position=center",
			"position=top-left",
			"position=top-center",
			"position=top-right",
			"position=bottom-left",
			"position=bottom-center",
			"position=bottom-right",
			"position=left-center",
			"position=right-center",
			"row=+10",
			"row=+20",
			"row=50%",
			"row=25%",
			"col=+10",
			"col=+20",
			"col=50%",
			"col=25%",
			"direction=top",
			"direction=bottom",
			"direction=left",
			"direction=right",
		}
	end,
	desc = "Reposition the current window (terminal or buffer)",
})

vim.api.nvim_create_user_command("TFlingListBuffers", function()
	local open_buffers = {}
	for name, instance in pairs(terms) do
		if instance.bufnr and vim.api.nvim_buf_is_valid(instance.bufnr) then
			local is_open = false
			if instance.win_id and vim.api.nvim_win_is_valid(instance.win_id) then
				is_open = true
			end
			table.insert(open_buffers, {
				name = name,
				bufnr = instance.bufnr,
				win_id = instance.win_id,
				is_open = is_open,
				cmd = instance.cmd,
			})
		end
	end

	if #open_buffers == 0 then
		vim.notify("No open tfling buffers", vim.log.levels.INFO)
		return
	end

	-- Sort by name for consistent output
	table.sort(open_buffers, function(a, b)
		return a.name < b.name
	end)

	-- Display the list
	local lines = { "Open tfling buffers:" }
	for _, buf_info in ipairs(open_buffers) do
		local status = buf_info.is_open and "[OPEN]" or "[HIDDEN]"
		table.insert(lines, string.format("  %s %s (buf: %d, cmd: %s)", status, buf_info.name, buf_info.bufnr, buf_info.cmd))
	end

	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, {
	desc = "List all open tfling buffers",
})

vim.api.nvim_create_user_command("TFlingGoToBuffer", function(opts)
	if not opts.args or opts.args == "" then
		vim.notify("Usage: TFlingGoToBuffer <name>", vim.log.levels.ERROR)
		vim.notify("Use :TFlingListBuffers to see available buffers", vim.log.levels.INFO)
		return
	end

	local name = opts.args:match("^%s*(.-)%s*$") -- trim whitespace
	local term_instance = terms[name]

	if not term_instance then
		vim.notify(string.format("No tfling buffer found with name: %s", name), vim.log.levels.ERROR)
		vim.notify("Use :TFlingListBuffers to see available buffers", vim.log.levels.INFO)
		return
	end

	if not term_instance.bufnr or not vim.api.nvim_buf_is_valid(term_instance.bufnr) then
		vim.notify(string.format("Buffer for '%s' is no longer valid", name), vim.log.levels.ERROR)
		return
	end

	-- Use toggle to either focus existing window or reopen with default config
	-- Since we don't store the original window config, use default floating window
	local win_config = defaults.apply_win_defaults({
		type = "floating",
	})
	term_instance:toggle({ win = win_config })
end, {
	nargs = 1,
	complete = function()
		local completions = {}
		for name, instance in pairs(terms) do
			if instance.bufnr and vim.api.nvim_buf_is_valid(instance.bufnr) then
				table.insert(completions, name)
			end
		end
		return completions
	end,
	desc = "Go to a specific tfling buffer by name",
})

return M
