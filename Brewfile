# Brewfile for Neovim configuration dependencies
# Install all with: brew bundle --file=Brewfile

# Core
brew "neovim"
brew "git"
brew "lazygit"

# Telescope dependencies
brew "ripgrep"   # live_grep
brew "fd"        # find_files

# LSP servers
brew "ast-grep"  # ast_grep
brew "marksman"  # markdown

# Formatters
brew "stylua"    # lua

# Node (for npm-based LSP servers and tools)
brew "nvm"

# Rust (for rust_analyzer)
brew "rustup"

# -----------------------------------------------------------------------------
# After brew bundle, run the following:
#
# Node global packages (npm install -g <package>):
#   vscode-langservers-extracted   # jsonls (JSON LSP)
#   yaml-language-server           # yamlls
#   sql-language-server            # sqlls
#   @vtsls/language-server         # vtsls (TypeScript/Vue LSP)
#   @vue/language-server           # vue_ls
#   prettier                       # formatter
#   eslint                         # linter
#
# Rust components (rustup component add <component>):
#   rust-analyzer
#
# Python tools (uv tool install <package>):
#   See requirements.txt
# -----------------------------------------------------------------------------
