return {
	"kkoomen/vim-doge",
	config = function()
		vim.g.doge_enable_mappings = 1

		local keymap = vim.keymap
		keymap.set("n", "<leader>dc", "<Plug>(doge-generate)", { desc = "doge - auto generate documentation" }) -- restore last workspace session for current directory
	end,
}
