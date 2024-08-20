-- how to use: go to project root and run
--     mkdir -p .cache
--     git clone https://github.com/nvim-neorocks/lz.n .cache/lz.n
--     nvim -u NORC --cmd 'luafile tests/test.lua' +q --headless

local project_dir = vim.fn.getcwd()

local function assertEq(a, b, ...)
	if a ~= b then
		local hint = ''
		if select("#", ...) > 0 then
			hint = table.concat({ 'Hint: ', ... }, ' ')
		end
		local msg = string.format([[assertion a == b failed:
		a = %s
		b = %s
	%s]], vim.inspect(a), vim.inspect(b), hint
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

	_G.foo_four_loaded_count = 0

	lzn.load({
		"foo",
		before = function() _G.before_triggered = true end,
		after = function()
			_G.after_triggered = true
			assertEq(require('foo.four'), 4)
		end,
		-- lz.n doesn't lazy load unless there is an "entry" condition
		cmd = "Fake",
	})

	assert(require('lz.n.state').plugins.foo, 'state: ' .. vim.inspect(require('lz.n.state')))

	local ok, value = pcall(require, 'foo.four')
	assertEq(ok, false, "got value:", value, "rtp:", vim.inspect(vim.opt.runtimepath:get()))

	auto_req.register_loader()

	assertEq(require('foo.four'), 4, "assert module foo.four returns 4")
	assertEq(_G.plugin_triggered, true, 'assert plugin/foo.lua is run')
	assertEq(foo_four_loaded_count, 1, 'assert module only evaluated once')
	assertEq(_G.before_triggered, true, 'assert "before" hook is triggered')
	assertEq(_G.after_triggered, true, 'assert "after" hook is triggered')

	print("test passed")
end

test()
