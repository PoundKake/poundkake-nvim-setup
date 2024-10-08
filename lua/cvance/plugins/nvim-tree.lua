return {
	"nvim-tree/nvim-tree.lua",
	dependencies = "nvim-tree/nvim-web-devicons",
	config = function()
		local nvimtree = require("nvim-tree")

		vim.g.loaded_netrw = 1
		vim.g.loaded_netrwPlugin = 1
		nvimtree.setup({
			view = {
				-- width = 40,
				adaptive_size = true,
				relativenumber = true,
			},
			renderer = {
				indent_markers = {
					enable = true,
				},
			},
			actions = {
				open_file = {
					window_picker = {
						enable = false,
					},
				},
			},
			filters = {
				custom = { ".DS_Store" },
			},
			git = {
				ignore = false,
			},
		})
		-- set keymaps
		local keymap = vim.keymap

		keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "toggle file explorer" })
		keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "collapse file explorer" })
		keymap.set(
			"n",
			"<leader>ef",
			"<cmd>NvimTreeFindFileToggle<CR>",
			{ desc = "toggle file explorer on current file" }
		)
		keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "refresh file explorer" })
	end,
}
