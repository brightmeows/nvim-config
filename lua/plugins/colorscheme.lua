-- colorscheme：主题应用与 catppuccin/tokyonight 的集成配置。
-- 行为源：LazyVim plugins/colorscheme.lua。
-- 此文件为静态应用版（当前主题）；步骤 5 的 Omarchy 兼容解析器
-- （meow.theme）将接管主题来源，读取上游生成的 neovim.lua。
return {
  {
    src = "https://github.com/folke/tokyonight.nvim",
    name = "tokyonight.nvim",
    config = function()
      require("tokyonight").setup({ style = "moon" })
    end,
  },
  {
    src = "https://github.com/catppuccin/nvim",
    name = "catppuccin",
    config = function()
      require("catppuccin").setup({
        lsp_styles = {
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        integrations = {
          aerial = true,
          alpha = true,
          cmp = true,
          dashboard = true,
          flash = true,
          fzf = true,
          grug_far = true,
          gitsigns = true,
          headlines = true,
          illuminate = true,
          indent_blankline = { enabled = true },
          leap = true,
          lsp_trouble = true,
          mason = true,
          mini = true,
          navic = { enabled = true, custom_bg = "lualine" },
          neotest = true,
          neotree = true,
          noice = true,
          notify = true,
          snacks = true,
          telescope = true,
          treesitter_context = true,
          which_key = true,
          blink_cmp = true,
        },
      })
      -- 当前主题应用（基线：Omarchy 生成 spec 的 opts.colorscheme = "catppuccin-nvim"；
      -- tokyonight 保留 moon style 作为回退）。步骤 5 起由 meow.theme 动态读取。
      pcall(vim.cmd.colorscheme, "catppuccin-nvim")

      -- catppuccin 的 bufferline 集成（LazyVim colorscheme.lua 的 specs 段等效）
      local ok, bufferline = pcall(require, "bufferline")
      if ok and (vim.g.colors_name or ""):find("catppuccin") then
        bufferline.setup({
          highlights = require("catppuccin.special.bufferline").get_theme(),
        })
      end
    end,
  },
}
