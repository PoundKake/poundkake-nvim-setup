return {
	"scottmckendry/cyberdream.nvim",
	priority = 1000,
	config = function()
		local transparent = true
		local theme = "default"
		local borderless_telescope = true

		require("cyberdream").setup({
			transparent = transparent,
			borderless_telescope = borderless_telescope,
			theme = { variant = theme },
		})

		vim.cmd("colorscheme cyberdream")
	end,
}
