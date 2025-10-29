--- @class AttachOpts
--- @field session_id string
--- @field cmd  table

--- @class AbducoAttachOpts
--- @field session_id string
--- @field cmd  table
--- @field exit_key?  string

--- @class SessionManager
--- @field create_or_attach_cmd fun(opts: AttachOpts): table

local abduco = {
	---@param opts AbducoAttachOpts
	---@return table
	create_or_attach_cmd = function(opts)
		return { "abduco", "-e", opts.exit_key or "^Q", "-A", opts.session_id, table.concat(opts.cmd, " ") }
	end,
}

local tmux = {
	---@param opts AttachOpts
	---@return table
	create_or_attach_cmd = function(opts)
		local mux = require("tfling.tmux")
		return mux.session({ start_cmd = opts.cmd, name = opts.session_id })
	end,
}

return {
	abduco = abduco,
	tmux = tmux,
}
