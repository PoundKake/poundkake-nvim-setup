# Plan: fix `Error running eslint: ENOENT` from nvim-lint

**Status:** APPLIED and verified 2026-08-11. All 4 success criteria below pass.
**Date:** 2026-08-11
**File to change:** `lua/cvance/plugins/linting.lua`
**Verified against:** Neovim 0.12.4, nvim-lint @ `a219b2c9`, eslint 9.39.4

---

## Symptom

On every `BufEnter` in a JS/TS/Vue buffer:

```
Error in BufEnter Autocommands for "*":
Error running eslint: ENOENT: no such file or directory
```

Fires from the `BufEnter, BufWritePost, InsertLeave` autocmd in `linting.lua:19-24`.
Cosmetic — nothing else breaks — but it prints constantly and hides real messages.

---

## Root cause

Two independent failures, both caused by Neovim's **cwd** not being the directory
that owns the ESLint install. Fixing only the first one is not enough.

### 1. Binary resolution

nvim-lint's builtin eslint linter
(`lazy/nvim-lint/lua/lint/linters/eslint.lua`) resolves its command like this:

```lua
cmd = function()
  local local_binary = vim.fn.fnamemodify('./node_modules/.bin/' .. binary_name, ':p')
  return vim.loop.fs_stat(local_binary) and local_binary or binary_name
end
```

`fnamemodify(..., ':p')` expands `./` against **Neovim's cwd**, not the buffer's path.

In `nebnext-toolkit` there is **no root `node_modules`** — ESLint lives at
`app/node_modules/.bin/eslint`. So opening `nvim` at the repo root misses it and
falls back to a bare `eslint`, which is not on `PATH` (no global install, no
Mason install) → `ENOENT`.

Verified:

| Neovim cwd | `require("lint.linters.eslint").cmd()` | Result |
|---|---|---|
| `nebnext-toolkit/` | `eslint` | ENOENT |
| `nebnext-toolkit/app/` | `.../app/node_modules/.bin/eslint` | works, no error |

### 2. Flat-config discovery (the half that's easy to miss)

ESLint 9 searches for `eslint.config.js` **from the process cwd**, not from the
file passed to `--stdin-filename`. This repo's config is at `app/eslint.config.js`.

So even with the correct binary, running from the repo root fails:

```console
$ cd nebnext-toolkit && cat app/src/.../ChartPreview.vue \
    | app/node_modules/.bin/eslint --format json --stdin --stdin-filename <abs path>
ESLint couldn't find an eslint.config.(js|mjs|cjs) file.

$ cd nebnext-toolkit/app && cat src/.../ChartPreview.vue \
    | ./node_modules/.bin/eslint --format json --stdin --stdin-filename <abs path>
[{"filePath":"...","messages":[],"errorCount":0,...}]
```

### Why one change fixes both

In `lazy/nvim-lint/lua/lint.lua`:

```lua
local cwd = opts.cwd or linter.cwd or vim.fn.getcwd()   -- :281 / :368
local function eval(...) return with_cwd(cwd, eval_fn_or_id, ...) end
...
local cmd = eval(linter.cmd)                             -- :411
```

`with_cwd` temporarily `:cd`s before evaluating `cmd`. So supplying `cwd`
makes the builtin `cmd` function resolve `./node_modules/.bin/eslint` correctly
**and** gives the spawned process the right directory for config discovery.
No need to override `cmd` at all.

Note `linter.cwd` is consumed raw — it must be a **string**, it is not passed
through `eval_fn_or_id`. Per-buffer values must go through `try_lint`'s
`opts.cwd` instead.

---

## The fix

Replace the autocmd in `lua/cvance/plugins/linting.lua:19-24`. Everything above
it (`linters_by_ft`, the augroup) stays as-is.

```lua
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

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
  group = lint_augroup,
  callback = function(args)
    local names = lint.linters_by_ft[vim.bo[args.buf].filetype]
    if not names then
      return
    end

    -- Skip eslint entirely when the project has no install, rather than
    -- falling back to a global binary that isn't there.
    local root = eslint_root(args.buf)
    local runnable = vim.tbl_filter(function(n)
      return n ~= "eslint" or root ~= nil
    end, names)

    if #runnable > 0 then
      lint.try_lint(runnable, root and { cwd = root } or {})
    end
  end,
})
```

The `<leader>l` keymap at `linting.lua:26-28` should get the same treatment if
you want manual triggering to behave identically — otherwise leave it.

---

## Verification

Success criteria, in order:

1. **No error on open.** `nvim` from the repo root, open any `.vue`/`.js`/`.ts`
   file. No `Error running eslint` message.
   ```console
   $ cd nebnext-toolkit && nvim app/src/applications/Thermocycler/components/ChartEditor2/ChartPreview.vue
   ```
2. **Root resolves.** `:lua print(vim.inspect(require("lint").linters_by_ft.vue))`
   still shows `{ "eslint" }`, and the helper returns `.../nebnext-toolkit/app`.
3. **Diagnostics actually appear.** Introduce a real violation (e.g. an unused
   variable), `:w`, and confirm a diagnostic shows. This is the step that proves
   the cwd fix worked rather than just silencing the error — do not skip it.
4. **No regression elsewhere.** Open a Python file and confirm `ruff` still runs;
   open a JS file in a project with **no** eslint install and confirm silence
   rather than ENOENT.

---

## Notes / caveats

- `with_cwd` performs a real `vim.cmd.cd()` and restores afterwards. It's
  nvim-lint's own mechanism, but it does mean a global cwd flicker during lint.
  Harmless in practice; worth knowing if something else watches `DirChanged`.
- If a filetype ever maps to *both* eslint and another linter, the current
  `linters_by_ft` is 1:1 so this doesn't arise. If it changes, the single
  `opts.cwd` would apply to both linters in that batch.
- **Alternative considered:** install `eslint_d` globally (nvim-lint ships an
  `eslint_d` linter). Faster, but it's another global dependency to keep in sync
  with the project's eslint version, and it has the same cwd/flat-config
  problem. Not recommended over the above.
- **Alternative considered:** hardcode `cwd = "<repo>/app"`. Works for this repo
  only and breaks every other project. Rejected.
- **Found while verifying (not anticipated by this plan): eslint now reports
  twice.** `lspconfig.lua:83` enables the `eslint` **LSP server**, which lints
  the same files independently. Before this fix nvim-lint's eslint always
  errored out, so only the LSP's diagnostics ever appeared. With nvim-lint
  working, both publish to separate namespaces and every eslint diagnostic
  shows up doubled:

  | ns name | source | origin |
  |---|---|---|
  | `eslint` | nvim-lint | this fix |
  | `nvim.lsp.eslint.1.eslint` | eslint LSP | `lspconfig.lua:83` |
  | `nvim.lsp.vtsls.2` | vtsls | TS server, partially overlaps |

  The eslint LSP resolves its own binary and flat config correctly (it has no
  cwd bug), so **dropping eslint from `linters_by_ft` entirely** is the likely
  right call — it makes this whole plan redundant. Left in place because that's
  a config-design decision, not part of executing this plan. Decide and then
  delete one of the two.
- Unrelated but adjacent: this config previously had zero treesitter parsers
  installed because `treesitter.lua` used the `master` API while pinned to
  `main`. That was fixed on 2026-08-11 alongside upgrading Neovim to 0.12.4.
