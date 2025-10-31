local M = {}

local util = require("tfling.util")

--- @class SessionOpts
--- @field name string
--- @field start_cmd? table

--- @param opts SessionOpts
function M.session(opts)
	local config_path = util.get_tmux_config_path()
	
	if M.session_exists(opts.name) then
		return { "tmux", "-f", config_path, "attach", "-t", opts.name }
	end

	local cmd = { "tmux", "-f", config_path, "new-session", "-s", opts.name }
	if opts.start_cmd ~= nil then
		table.insert(cmd, table.concat(opts.start_cmd, " "))
	end

	return cmd
end

--- @class KillSessionOpts
--- @field name string session name to kill
--- @field tmux_cmd? table custom tmux command

--- @param opts KillSessionOpts
function M.kill_session(opts)
	local config_path = util.get_tmux_config_path()
	local cmd = { "tmux", "-f", config_path, "kill-session", "-t", opts.name }
	if opts.tmux_cmd ~= nil then
		cmd = opts.tmux_cmd
	end
	return cmd
end

--- Check if a tmux session exists
--- @param session_name string
--- @return boolean
function M.session_exists(session_name)
	local config_path = util.get_tmux_config_path()
	local result = vim.system({ "tmux", "-f", config_path, "has-session", "-t", session_name }):wait()
	return result.code == 0
end

--- @class AttachSessionOpts
--- @field name string session name to attach to

--- @param opts AttachSessionOpts
function M.attach_session(opts)
	local config_path = util.get_tmux_config_path()
	-- Return the attach command
	return "tmux -f " .. config_path .. " attach-session -t " .. opts.name
end

return M
