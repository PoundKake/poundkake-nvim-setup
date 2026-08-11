local ensure_installed = {
	"json",
	"javascript",
	"typescript",
	"yaml",
	"html",
	"css",
	"markdown",
	"markdown_inline",
	"bash",
	"lua",
	"vim",
	"vimdoc",
	"ruby",
	"nginx",
	"c_sharp",
	"arduino",
	"dockerfile",
	"gitignore",
	"c",
	"cpp",
	"sql",
	"vue",
	"python",
}

return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	dependencies = {
		{ "windwp/nvim-ts-autotag", opts = {} },
	},
	config = function()
		local ts = require("nvim-treesitter")

		ts.setup()

		-- `main` has no `ensure_installed`; install whatever is missing, once.
		local installed = ts.get_installed()
		local missing = vim.tbl_filter(function(lang)
			return not vim.tbl_contains(installed, lang)
		end, ensure_installed)
		if #missing > 0 then
			ts.install(missing)
		end

		-- `main` also dropped the `highlight`/`indent` modules; start the parser
		-- ourselves. `vim.treesitter.start` errors when a language has no parser,
		-- so pcall doubles as the "is it installed" check.
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("cvance_treesitter", { clear = true }),
			callback = function(args)
				if pcall(vim.treesitter.start, args.buf) then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
