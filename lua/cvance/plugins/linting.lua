return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			javascript = { "eslint" },
			vue = { "eslint" },
			typescript = { "eslint" },
			javascriptreact = { "eslint" },
			typescriptreact = { "eslint" },
			svelte = { "eslint" },
			python = { "ruff" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		-- nvim-lint resolves `./node_modules/.bin/eslint` and ESLint 9 discovers
		-- `eslint.config.js` both relative to the *process cwd*, not the buffer path.
		-- Monorepos that keep eslint in a subdir (e.g. nebnext-toolkit/app) miss both
		-- when nvim is opened at the repo root. Find the owning dir per buffer.
		local function eslint_root(bufnr)
			local fname = vim.api.nvim_buf_get_name(bufnr)
			if fname == "" then
				return nil
			end
			for _, nm in ipairs(vim.fs.find("node_modules", {
				upward = true,
				type = "directory",
				path = vim.fs.dirname(fname),
				limit = math.huge,
			})) do
				if vim.uv.fs_stat(nm .. "/.bin/eslint") then
					return vim.fs.dirname(nm)
				end
			end
			return nil
		end

		local function lint_buf(bufnr)
			local names = lint.linters_by_ft[vim.bo[bufnr].filetype]
			if not names then
				return
			end

			-- Skip eslint entirely when the project has no install, rather than
			-- falling back to a global binary that isn't there.
			local root = eslint_root(bufnr)
			local runnable = vim.tbl_filter(function(n)
				return n ~= "eslint" or root ~= nil
			end, names)

			if #runnable > 0 then
				lint.try_lint(runnable, root and { cwd = root } or {})
			end
		end

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function(args)
				lint_buf(args.buf)
			end,
		})

		vim.keymap.set("n", "<leader>l", function()
			lint_buf(vim.api.nvim_get_current_buf())
		end, { desc = "Trigger linting for current file" })
	end,
}
