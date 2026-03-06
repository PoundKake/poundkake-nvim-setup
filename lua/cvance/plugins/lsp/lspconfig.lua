return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		local cmp_nvim_lsp = require("cmp_nvim_lsp")
		local keymap = vim.keymap

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }

				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
			end,
		})

		local capabilities = cmp_nvim_lsp.default_capabilities()

		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.INFO] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
				},
				linehl = {
					[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
					[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
					[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
					[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
				},
			},
		})

		-- Configure LSP servers using vim.lsp.config (Neovim 0.11+)
		local servers = { "ast_grep", "eslint", "jsonls", "sqlls", "yamlls", "marksman", "rust_analyzer", "ty" }
		for _, server in ipairs(servers) do
			vim.lsp.config(server, { capabilities = capabilities })
		end

		-- vtsls with @vue/typescript-plugin for Vue hybrid mode support
		local vue_language_server_path = vim.fn.expand("$HOME/.nvm/versions/node/v24.13.0/lib/node_modules/@vue/language-server")
		vim.lsp.config("vtsls", {
			capabilities = capabilities,
			filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
			settings = {
				vtsls = {
					tsserver = {
						globalPlugins = {
							{
								name = "@vue/typescript-plugin",
								location = vue_language_server_path,
								languages = { "vue" },
								configNamespace = "typescript",
							},
						},
					},
				},
			},
		})

		-- Vue language server (hybrid mode — handles HTML/CSS, vtsls handles TS/JS)
		vim.lsp.config("vue_ls", {
			capabilities = capabilities,
			on_init = function(client)
				local retries = 0
				local function typescriptHandler(_, result, context)
					local ts_client = vim.lsp.get_clients({ bufnr = context.bufnr, name = "vtsls" })[1]
						or vim.lsp.get_clients({ bufnr = context.bufnr, name = "ts_ls" })[1]
						or vim.lsp.get_clients({ bufnr = context.bufnr, name = "typescript-tools" })[1]

					if not ts_client then
						if retries <= 30 then
							retries = retries + 1
							vim.defer_fn(function()
								typescriptHandler(_, result, context)
							end, 200)
						end
						return
					end

					local param = unpack(result)
					local id, command, payload = unpack(param)
					ts_client:exec_cmd({
						title = "vue_request_forward",
						command = "typescript.tsserverRequest",
						arguments = { command, payload },
					}, { bufnr = context.bufnr }, function(_, r)
						local response_data = { { id, r and r.body } }
						client:notify("tsserver/response", response_data)
					end)
				end
				client.handlers["tsserver/request"] = typescriptHandler
			end,
		})

		-- Enable all configured servers
		vim.lsp.enable(vim.list_extend(servers, { "vtsls", "vue_ls" }))
	end,
}
