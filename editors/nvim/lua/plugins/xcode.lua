return {
  "lunacookies/vim-colors-xcode",
  name = "xcode",
  lazy = false,
  priority = 1000,
  config = function()
    vim.cmd("colorscheme xcode")
  end,
}
