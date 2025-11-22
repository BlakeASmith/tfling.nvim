local M = {}

FloatingDefaults = {
	type = "floating",
	height = "80%",
	width = "80%",
	position = "top-center",
	margin = "5%",
}

VerticalSplitDefaults = {
	type = "split",
	size = "30%",
	direction = "right",
}

HorizontalSplitDefaults = {
	type = "split",
	size = "40%",
	direction = "bottom",
}

function ApplyDefaults(tbl, defaults)
	local applied = {}
	for key, value in pairs(tbl) do
		applied[key] = value or defaults[key]
	end

	-- There may be keys in defaults which are not in tbl
	for key, value in pairs(defaults) do
		if applied[key] == nil then
			applied[key] = value
		end
	end
	return applied
end

local is_vertical = function(opts)
	return opts.direction == "bottom" or opts.direction == "top"
end

---
-- Sets default win config
--- @param opts termSplitWin | termFloatingWin
function M.apply_win_defaults(opts)
	if opts.type == "floating" then
		opts = ApplyDefaults(opts, FloatingDefaults)
	elseif opts.type == "split" then
		if is_vertical(opts) then
			opts = ApplyDefaults(opts, VerticalSplitDefaults)
		else
			opts = ApplyDefaults(opts, HorizontalSplitDefaults)
		end
	else
		return ApplyDefaults(opts, FloatingDefaults)
	end
	return opts
end

return M
