-- mini.icons：图标。行为源：LazyVim plugins/ui.lua 的 mini.icons spec
-- （lazy=true；preload 段在 init 执行——须早于任何 require("nvim-web-devicons")，
-- 与基线同位；require 会触发未加载插件的加载）。
return {
  "https://github.com/nvim-mini/mini.icons",
  lazy = true,
  init = function()
    package.preload["nvim-web-devicons"] = function()
      require("mini.icons").mock_nvim_web_devicons()
      return package.loaded["nvim-web-devicons"]
    end
  end,
  config = function()
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
