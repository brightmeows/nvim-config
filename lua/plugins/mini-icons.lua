-- mini.icons：图标。行为源：LazyVim plugins/ui.lua 的 mini.icons spec。
-- preload 段保证 require("nvim-web-devicons") 落到 mini.icons mock（LazyVim 同款）。
return {
  src = "https://github.com/nvim-mini/mini.icons",
  name = "mini.icons",
  config = function()
    package.preload["nvim-web-devicons"] = function()
      require("mini.icons").mock_nvim_web_devicons()
      return package.loaded["nvim-web-devicons"]
    end
    require("mini.icons").setup({
      file = {
        [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
        ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
      },
      filetype = {
        dotenv = { glyph = "", hl = "MiniIconsYellow" },
      },
    })
  end,
}
