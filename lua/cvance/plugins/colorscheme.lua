return {
	"folke/tokyonight.nvim",
	priority = 1000,
	config = function()
		local transparent = true
		require("tokyonight").setup({
			style = "night",
			transparent = transparent,
		})

		vim.cmd("colorscheme tokyonight")
	end,
}
