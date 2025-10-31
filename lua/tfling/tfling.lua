-- File: lua/floating_term.lua

local M = {}

local Terminal = {}
Terminal.__index = Terminal
local active_instances = {}

local util = require("tfling.util")
local get_selected_text = util.get_selected_text
local defaults = require("tfling.defaults")
local geometry = require("tfling.geometry")
local window_ops = require("tfling.window_ops")
local commands = require("tfling.commands")


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
	local term_instance = active_instances[current_win]
	if term_instance then
		term_instance:hide()
	end
end

local terms = {}

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
						window_ops.resize(term_instance.win_id, options)
					end,
					reposition = function(options)
						local term_instance = terms[opts.name]
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

local Config = {
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
	desc = "Reposition the current terminal window",
})

return M
