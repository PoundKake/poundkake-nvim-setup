return {
	"scottmckendry/cyberdream.nvim",
	priority = 1000,
	config = function()
		local transparent = true
		local theme = "light" -- default, light, auto
		local borderless_telescope = true

		require("cyberdream").setup({
			transparent = transparent,
			borderless_telescope = borderless_telescope,
			theme = { variant = theme },
		})

		vim.cmd("colorscheme cyberdream")
	end,
}
