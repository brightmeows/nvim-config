-- colorscheme：主题应用与 catppuccin/tokyonight 的集成配置。
-- 行为源：LazyVim plugins/colorscheme.lua（两件均 lazy=true；catppuccin 的
-- bufferline 集成走 specs 段合并到 bufferline 的 opts）。
-- 差异：静态回退应用（原 config 内 pcall colorscheme）随懒加载迁至
-- meow.theme.load 的非 Omarchy 分支——catppuccin 变 lazy 后需由外部
-- colorscheme 调用触发 ColorSchemePre 加载。
return {
  {
    "https://github.com/folke/tokyonight.nvim",
    lazy = true,
    config = function()
      require("tokyonight").setup({ style = "moon" })
    end,
  },
  {
    "https://github.com/catppuccin/nvim",
    name = "catppuccin",
    lazy = true,
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
    end,
    -- catppuccin 的 bufferline 集成（行为源：LazyVim colorscheme.lua 的
    -- specs 段，optional 合并；bufferline 加载时 colors_name 已应用）
    specs = {
      {
        "https://github.com/akinsho/bufferline.nvim",
        optional = true,
        opts = function(_, opts)
          if (vim.g.colors_name or ""):find("catppuccin") then
            opts.highlights = require("catppuccin.special.bufferline").get_theme()
          end
        end,
      },
    },
  },
}
