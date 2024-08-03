-- how to use: go to project root and run
--     mkdir -p .cache
--     git clone https://github.com/nvim-neorocks/lz.n .cache/lz.n
--     nvim -u NORC --cmd 'luafile tests/test.lua' +q --headless

local project_dir = vim.fn.getcwd()

local function assertEq(a, b, ...)
	if a ~= b then
		print("Hint", ...)
		local msg = string.format([[assertion a == b failed:
		a = %s
		b = %s]], vim.inspect(a), vim.inspect(b)
		)
		error(msg)
	end
end

local function test()
	vim.opt.runtimepath:prepend(project_dir .. '/.cache/lz.n')
	vim.opt.runtimepath:prepend(project_dir)
	vim.opt.packpath:append(vim.fs.joinpath(project_dir, "tests/runtime"))

	vim.print('    == runtimepath:', table.concat(vim.opt.runtimepath:get(), '\n'))
	vim.print('    == packpath:', table.concat(vim.opt.packpath:get(), '\n'))
	print('--------------------')

	local lzn = require('lz.n')
	local auto_req = require('lzn-auto-require.loader')

	-- lz.n doesn't lazy load unless there is an "entry" condition
	lzn.load({ "foo", after = function() print('foo.four loaded:', require('foo.four')) end, cmd = "Fake" })

	local ok, value = pcall(require, 'foo.four')
	assertEq(ok, false, "got value:", value, "rtp:", vim.inspect(vim.opt.runtimepath:get()))

	auto_req.register_loader()

	assertEq(require('foo.four'), 4)
end

test()
