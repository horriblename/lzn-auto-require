local M = {}

---find_opt_file({'lua/x.lua'}) returns the first match of '(packpath)/opt/*/lua/x.lua'
---@param relPaths string[] @return string? pack_name, string? full_path
---@return boolean found,  string|string[] pathOrTriedPaths, string? pack_name
local function find_opt_file(relPaths)
	local triedPaths = {}
	for _, pack in ipairs(vim.opt.packpath:get()) do
		local optPath = vim.fs.joinpath(pack, 'opt')
		if vim.fn.isdirectory(optPath) == 0 then
			goto continue
		end

		for plugDir, typ in vim.fs.dir(optPath) do
			local pluginPath = vim.fs.joinpath(optPath, plugDir)
			if typ ~= "directory" then
				goto continue2
			end

			for _, relPath in ipairs(relPaths) do
				local fullPath = vim.fs.joinpath(pluginPath, relPath)
				if vim.fn.filereadable(fullPath) then
					print('full', fullPath, 'pack_name', plugDir, 'plugPath', pluginPath)
					return true, fullPath, plugDir
				end

				table.insert(triedPaths, fullPath)
			end

			::continue2::
		end
		::continue::
	end

	return false, triedPaths
end

---@param mod string
---@return nil|string|fun() loader
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

	require('lz.n').trigger_load(pack_name)
	return assert(loadfile(file_path --[[@as string]]))
end

function M.register_loader()
	table.insert(package.loaders, M.search)
end

return M
