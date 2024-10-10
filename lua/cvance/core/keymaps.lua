vim.g.mapleader = " "
local keymap = vim.keymap

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "clear search highlights" })

-- Window Management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "splits window vertically" })
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "splits window horizontally" })
keymap.set("n", "<leader>se", "<C-w>=", { desc = "make window splits equal size" })
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "open a new tab" })
keymap.set("n", "<leader>tw", "<cmd>tabclose<CR>", { desc = "close current tab" })
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "go to next tab" })
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "go to previous tab" })
keymap.set("n", "<leader>tf", "<cmd>tabnew<CR>", { desc = "open current buffer in new tab" })
