return {
	"navarasu/onedark.nvim",
	priority = 1000,
	config = function()
		local transparent = true
		-- local theme = "auto" -- default, light, auto
		local theme = "deep" -- default, light, auto
		-- local borderless_telescope = true

		require("onedark").setup({
			transparent = transparent,
			style = theme,
			-- borderless_telescope = borderless_telescope,
			-- theme = { variant = theme },
		})

		vim.cmd("colorscheme onedark")
	end,
}
