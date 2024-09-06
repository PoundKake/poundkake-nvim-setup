return {
  "folke/tokyonight.nvim",
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      style = "day",
    })

    vim.cmd("colorscheme tokyonight-day")
  end,
}
