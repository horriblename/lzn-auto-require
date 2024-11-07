return {
	register_loader = function()
		vim.deprecate(
			"lzn-auto-require.loader.register_loader",
			"require('lzn-auto-require').enable()",
			"0.3.0",
			"lzn-auto-require"
		)

		require('lzn-auto-require').enable()
	end
}
