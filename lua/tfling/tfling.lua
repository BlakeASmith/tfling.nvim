local M = {}

-- Window type constants (for internal use)
local WINDOW_TYPE = {
	FLOATING = "floating",
	SPLIT = "split",
}

-- Split position constants
local SPLIT_POSITION = {
	TOP = "split-top",
	BOTTOM = "split-bottom",
	LEFT = "split-left",
	RIGHT = "split-right",
}

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

-- Terminal instance management
local Terminal = {}
Terminal.__index = Terminal
local active_instances = {}
local terms = {}

-- Constants
local DEFAULT_SEND_DELAY = 100 -- milliseconds
local MIN_WINDOW_PADDING = 2 -- minimum padding from screen edges

-- Configuration
local Config = {
	always = function(term) end,
	send_delay = DEFAULT_SEND_DELAY,
}

local util = require("tfling.util")
local get_selected_text = util.get_selected_text
local defaults = require("tfling.defaults")
local geometry = require("tfling.geometry")
local window_ops = require("tfling.window_ops")
local commands = require("tfling.commands")

--- Create a new terminal instance
--- @param config table configuration table with cmd field
--- @return table|nil terminal instance or nil if creation fails
local function create_terminal(config)
	if not config or not config.cmd then
		vim.notify("tfling: create_terminal() requires 'cmd' field", vim.log.levels.ERROR)
		return nil
	end

	local instance = setmetatable({}, Terminal)
	instance.cmd = config.cmd
	instance.win_opts = config.win_opts or {} -- Legacy support
	instance.bufnr = nil
	instance.win_id = nil
	instance.job_id = nil
	return instance
end

--- Toggle terminal window visibility
--- @param opts table optional configuration with win field
function Terminal:toggle(opts)
	if opts == nil then
		self:hide()
		return
	end

	if opts.win then
		local win_config = defaults.apply_win_defaults(opts.win)
		opts.win = win_config
	end

	if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
		if opts.win and not is_split_position(opts.win.position) then
			-- Floating window - update geometry
			vim.api.nvim_win_set_config(self.win_id, geometry.floating(opts.win))
			vim.api.nvim_set_current_win(self.win_id)
		else
			-- For splits, just focus the existing window
			vim.api.nvim_set_current_win(self.win_id)
		end
	else
		self:open(opts)
	end
end

--- Hide the terminal window
function Terminal:hide()
	if not (self.win_id and vim.api.nvim_win_is_valid(self.win_id)) then
		return
	end
	active_instances[self.win_id] = nil
	vim.api.nvim_win_close(self.win_id, true)
	self.win_id = nil
end

--- Open the terminal window
--- @param opts table optional configuration with win field
function Terminal:open(opts)
	local win_config = defaults.apply_win_defaults(opts.win)

	-- If window is valid, just focus it
	if self.win_id and vim.api.nvim_win_is_valid(self.win_id) then
		vim.api.nvim_set_current_win(self.win_id)
		return
	end

	-- If buffer exists, create window based on position
	if self.bufnr and vim.api.nvim_buf_is_valid(self.bufnr) then
		if is_split_position(win_config.position) then
			self:_create_split_window(win_config)
		else
			self.win_id = vim.api.nvim_open_win(self.bufnr, true, geometry.floating(win_config))
		end
		active_instances[self.win_id] = self
		self:setup_win_options()
		vim.cmd("startinsert")
		return
	end

	-- Create new buffer and window
	self.bufnr = vim.api.nvim_create_buf(true, true)
	vim.bo[self.bufnr].bufhidden = "hide"
	vim.bo[self.bufnr].filetype = "tfling"

	if is_split_position(win_config.position) then
		self:_create_split_window(win_config)
	else
		self.win_id = vim.api.nvim_open_win(self.bufnr, true, geometry.floating(win_config))
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

--- Create a split window for the terminal
--- @param win_config table window configuration with position, width, and height fields
function Terminal:_create_split_window(win_config)
	local direction = get_split_direction(win_config.position)
	
	if not direction then
		vim.notify("tfling: invalid split position: " .. (win_config.position or "nil"), vim.log.levels.ERROR)
		return
	end

	local is_horizontal = direction == "top" or direction == "bottom"

	if is_horizontal then
		-- Horizontal split - use height
		local size_percent = tonumber(((win_config.height or "40%"):gsub("%%", "")))
		local actual_size = math.floor(vim.o.lines * (size_percent / 100))
		if direction == "top" then
			vim.cmd("topleft split")
		else
			vim.cmd("botright split")
		end
		vim.cmd("resize " .. actual_size)
	else
		-- Vertical split - use width
		local size_percent = tonumber(((win_config.width or "30%"):gsub("%%", "")))
		local actual_size = math.floor(vim.o.columns * (size_percent / 100))
		if direction == "left" then
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

--- Setup window options for the terminal window
function Terminal:setup_win_options()
	if vim.api.nvim_win_get_config(self.win_id).relative == "editor" then
		vim.wo[self.win_id].winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"
	end
	vim.wo[self.win_id].relativenumber = false
	vim.wo[self.win_id].number = false
	vim.wo[self.win_id].signcolumn = "no"
end

--- Hide the current terminal window
function M.hide_current()
	local term_instance = active_instances[vim.api.nvim_get_current_win()]
	if term_instance then
		term_instance:hide()
	end
end

--- @class termResizeOptions
--- @field width? number|string width as number, percentage ("50%"), or relative ("+5%")
--- @field height? number|string height as number, percentage ("50%"), or relative ("+5%")

--- @class termRepositionOptions
--- @field position? "center" | "top-left" | "top-center" | "top-right" | "bottom-left" | "bottom-right" | "bottom-center" | "left-center" | "right-center" | "split-top" | "split-bottom" | "split-left" | "split-right" position for repositioning
--- @field row? number|string row position as number, percentage ("50%"), or relative ("+10")
--- @field col? number|string column position as number, percentage ("50%"), or relative ("+10")

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

--- @class termWin
--- @field position? "center" | "top-left" | "top-center" | "top-right" | "bottom-left" | "bottom-right" | "bottom-center" | "left-center" | "right-center" | "split-top" | "split-bottom" | "split-left" | "split-right" position of window (defaults to "center" for floating)
--- @field size? string size as a percentage like "80%" - for floating: sets both width and height; for splits: sets width (vertical) or height (horizontal). Mutually exclusive with width/height.
--- @field width? string width as a percentage like "80%" (for floating windows, or split-left/split-right). Mutually exclusive with size.
--- @field height? string height as a percentage like "80%" (for floating windows, or split-top/split-bottom). Mutually exclusive with size.
--- @field margin? string margin as a percentage like "2%" (for floating windows only, defaults to "5%")

--- @class termTerm
--- @field name? string the name (needs to be unique, defaults to cmd)
--- @field cmd string the command/program to run
--- @field tmux? boolean whether to use tmux for this terminal (defaults to false)
--- @field abduco? boolean whether to use abduco for this terminal (defaults to false)
--- @field win? termWin window configuration (defaults to floating center)
--- @field send_delay? number delay in milliseconds before sending commands (defaults to global config)
--- @field setup? fun(details: termTermDetails) function to run on mount (receives termTermDetails table)

--- @param opts termTerm
function M.term(opts)
	if opts.setup == nil then
		opts.setup = function() end
	end

	if opts.win == nil then
		opts.win = {
			position = "center",
		}
	end

	-- Set default name to cmd if not provided
	if opts.name == nil then
		opts.name = opts.cmd
	end

	-- Handle tmux-backed terminals
	local actual_cmd = opts.cmd
	if opts.tmux then
		actual_cmd = table.concat(require("tfling.sessions").tmux.create_or_attach_cmd({
			session_id = "tfling-" .. (opts.name or opts.cmd),
			cmd = vim.split(opts.cmd, " "),
		}), " ")
	elseif opts.abduco then
		actual_cmd = table.concat(require("tfling.sessions").abduco.create_or_attach_cmd({
			session_id = "tfling-" .. (opts.name or opts.cmd),
			cmd = vim.split(opts.cmd, " "),
		}), " ")
	end

	-- Capture selected text BEFORE any buffer operations
	local captured_selected_text = get_selected_text()

	-- Get or create terminal instance
	local term_instance = terms[opts.name]
	if not term_instance then
		term_instance = create_terminal({
			cmd = actual_cmd,
			win_opts = {}, -- Legacy support
		})
		if not term_instance then
			return -- Error already notified
		end
		terms[opts.name] = term_instance
	end

	-- Apply defaults to win configuration
	opts.win = defaults.apply_win_defaults(opts.win)
	term_instance:toggle(opts)

	-- Call setup function in autocommand
	vim.api.nvim_create_augroup("tfling." .. opts.name .. ".config", {
		-- reset each time we enter
		clear = true,
	})
	-- on terminal enter (the window opening)
	vim.api.nvim_create_autocmd("TermEnter", {
		group = "tfling." .. opts.name .. ".config",
		-- only apply in the buffer created for this program
		buffer = term_instance.bufnr,
		callback = function()
			-- Create a table with terminal details to pass to the callback
			local term_details = {
				job_id = term_instance.job_id,
				bufnr = term_instance.bufnr,
				win_id = term_instance.win_id,
				name = opts.name,
				cmd = actual_cmd,
				selected_text = captured_selected_text, -- Use the captured text
				-- Helper function to send commands to this terminal
				send = function(command)
					if term_instance and term_instance.job_id then
						-- Use per-terminal send_delay if provided, otherwise fall back to global config
						vim.defer_fn(function()
							vim.api.nvim_chan_send(term_instance.job_id, command)
						end, opts.send_delay or Config.send_delay or DEFAULT_SEND_DELAY)
					end
				end,
				-- Helper function to resize the terminal window
				win = {
					resize = function(options)
						if not term_instance or not term_instance.win_id then
							return
						end
						window_ops.resize(term_instance.win_id, options)
					end,
					reposition = function(options)
						if not term_instance or not term_instance.win_id then
							return
						end
						window_ops.reposition(term_instance.win_id, options, term_instance)
					end,
				},
			}
			Config.always(term_details)
			opts.setup(term_details)
		end,
	})
end

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

vim.api.nvim_create_user_command("TFlingHideCurrent", M.hide_current, {})

vim.api.nvim_create_user_command("TFlingResizeCurrent", commands.create_resize_command(active_instances, terms), {
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
	desc = "Resize the current terminal window",
})

vim.api.nvim_create_user_command("TermRepositionCurrent", commands.create_reposition_command(active_instances, terms), {
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
			"position=split-top",
			"position=split-bottom",
			"position=split-left",
			"position=split-right",
			"row=+10",
			"row=+20",
			"row=50%",
			"row=25%",
			"col=+10",
			"col=+20",
			"col=50%",
			"col=25%",
		}
	end,
	desc = "Reposition the current terminal window",
})

return M
