local M = {}

---find_opt_file({'lua/x.lua'}) returns the first match of '(packpath)/opt/*/lua/x.lua'
---@param relPaths string[] @return string? pack_name, string? full_path
local function find_opt_file(relPaths)
	for _, pack in ipairs(vim.opt.packpath:get()) do
		local optPath = vim.fs.joinpath(pack, 'opt')
		if vim.fn.isdirectory(optPath) == 0 then
			goto continue
		end

		for plugDir in vim.fn.glob(optPath .. '/*') do
			local plugPath = vim.fs.joinpath(optPath, plugDir)
			if vim.fn.isdirectory(plugPath) == 0 then
				goto continue2
			end

			for _, relPath in ipairs(relPaths) do
				if vim.fn.filereadable(vim.fs.joinpath(plugPath, relPath)) then
					return relPath
				end
			end

			::continue2::
		end
		::continue::
	end

	return nil
end

---@param mod string
---@return nil|string|fun() loader
function M.search(mod)
	local segments = {}
	for str in string.gmatch(mod, '[^.]+') do
		table.insert(segments, str)
	end

	local p = vim.fs.joinpath('lua', unpack(segments))
	local pack_name, file_path = find_opt_file({ p .. '.lua', vim.fs.joinpath(p, 'init.lua') })

	if pack_name == nil then
		return nil
	end

	return M.loaderFactory(pack_name, file_path)
end

function M.loaderFactory(pack_name, file_path)
	return function()
		require('lz.n').trigger_load(pack_name)
		return assert(loadfile(file_path))
	end
end

function M.registerLoader()
	table.insert(package.loaders, M.search)
end

return M
