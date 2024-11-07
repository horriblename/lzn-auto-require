local M = {}
local lzn = require('lz.n')

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

---@type nil|fun(string):any
local builtin_require = nil

---@param mod string
---@return any
local function require(mod)
	assert(builtin_require)
	local ok, value = pcall(builtin_require, mod)
	if ok then
		return value
	end

	local segments = {}
	for str in string.gmatch(mod, '[^.]+') do
		table.insert(segments, str)
	end

	local p = vim.fs.joinpath('lua', unpack(segments))
	local found, file_path, pack_name = find_opt_file({ p .. '.lua', vim.fs.joinpath(p, 'init.lua') })

	if not found then
		error(value)
	end

	local plugin_spec = lzn.lookup(pack_name)
	if not plugin_spec then
		return assert(loadfile(file_path --[[@as string]]))
	end

	lzn.trigger_load(pack_name)
	return builtin_require(mod)
end

function M.enable()
	if builtin_require ~= nil then
		return
	end

	builtin_require = _G.require
	_G.require = require
end

function M.disable()
	if builtin_require == nil then
		return
	end

	_G.require = builtin_require
	builtin_require = nil
end

return M
