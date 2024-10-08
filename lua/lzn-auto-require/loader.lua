local M = {}
local lzn_loader = require('lz.n.loader')

---find_opt_file({'lua/x.lua'}) returns the first match of '(packpath)/pack/*/opt/{pack_name}/lua/x.lua'
---@param relPaths string[] @return string? pack_name, string? full_path
---@return boolean found,  string|string[] pathOrTriedPaths, string? pack_name
local function find_opt_file(relPaths)
	-- note to self: iterators are not helpful, vim.iter lacks flatten for function iterators,
	-- and trying to write an iterator library for such is absolutely braindead
	--
	-- embrace the ugly for loop and forget about it

	local triedPaths = {}
	for _, packpath in ipairs(vim.opt.packpath:get()) do
		local groupsPath = vim.fs.joinpath(packpath, 'pack')
		if vim.fn.isdirectory(groupsPath) == 1 then
			for group in vim.fs.dir(groupsPath) do
				-- {pack}/pack/{group}
				local groupPath = vim.fs.joinpath(groupsPath, group)

				for pack_name in vim.fs.dir(groupPath .. '/opt') do
					-- {pack}/pack/{group}/opt/{pack_name}
					local pack_path = vim.fs.joinpath(groupPath, 'opt', pack_name)
					if vim.g.lzn_auto_require_debug == 1 then
						vim.notify("[lzn-auto-reqire] searching in: " .. pack_path)
					end

					for _, relPath in ipairs(relPaths) do
						-- {pack}/pack/{group}/opt/{pack_name}/{relPath}
						local fullPath = vim.fs.joinpath(pack_path, relPath)
						if vim.fn.filereadable(fullPath) == 1 then
							return true, fullPath, pack_name
						end
					end

					table.insert(triedPaths, pack_path)
				end
			end
		end
	end

	return false, triedPaths
end

-- copied from lz.n
---@param hook_key hook_key
---@param plugin lz.n.Plugin
local function hook(hook_key, plugin)
	if type(plugin[hook_key]) == "function" then
		xpcall(
			plugin[hook_key],
			vim.schedule_wrap(function(err)
				vim.notify(
					"Failed to run '" .. hook_key .. "' hook for " .. plugin.name .. ": " .. tostring(err or ""),
					vim.log.levels.ERROR
				)
			end),
			plugin
		)
	end
end

---@param mod string
---@return nil|string|fun():any loader
function M.search(mod)
	local segments = {}
	for str in string.gmatch(mod, '[^.]+') do
		table.insert(segments, str)
	end

	local p = vim.fs.joinpath('lua', unpack(segments))
	local found, file_path, pack_name = find_opt_file({ p .. '.lua', vim.fs.joinpath(p, 'init.lua') })

	if not found then
		return 'no file:\n    ' .. table.concat(file_path --[[ @as string[] ]], '\n    ')
	end

	local plugin_spec = require('lz.n').lookup(pack_name)
	if not plugin_spec then
		return assert(loadfile(file_path --[[@as string]]))
	end

	return function()
		hook('before', plugin_spec)
		-- HACK: it's probably more correct to do _load then loadfile, but if we do
		-- that and mod is required somewhere in _load (i.e. a plugin/*.lua script), we
		-- get an import loop error
		package.loaded[mod] = assert(loadfile(file_path --[[@as string]]))()
		lzn_loader._load(plugin_spec)
		hook('after', plugin_spec)
		return package.loaded[mod]
	end
end

function M.register_loader()
	table.insert(package.loaders, M.search)
end

return M
