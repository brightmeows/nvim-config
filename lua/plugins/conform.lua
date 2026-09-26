-- conform：格式化。行为源：LazyVim plugins/formatting.lua。
-- 差异：LazyVim.format.register 走 meow.format；on_very_lazy 延迟注册改为
-- 直接注册（vim.pack 全量加载，无需 VeryLazy）。
return {
  src = "https://github.com/stevearc/conform.nvim",
  name = "conform.nvim",
  config = function()
    local meow = require("meow")

    -- LazyVim 的 conform setup 包装：拦截误用 format_on_save 的配置
    local opts = {
      default_format_opts = {
        timeout_ms = 3000,
        async = false,
        quiet = false,
        lsp_format = "fallback",
      },
      formatters_by_ft = {
        lua = { "stylua" },
        fish = { "fish_indent" },
        sh = { "shfmt" },
      },
      formatters = {
        injected = { options = { ignore_errors = true } },
      },
    }
    require("conform").setup(opts)

    -- 注册进 meow.format（LazyVim：conform init 的 on_very_lazy 段）
    meow.format.register({
      name = "conform.nvim",
      priority = 100,
      primary = true,
      format = function(buf)
        require("conform").format({ bufnr = buf })
      end,
      sources = function(buf)
        local ret = require("conform").list_formatters(buf)
        return vim.tbl_map(function(v)
          return v.name
        end, ret)
      end,
    })

    -- LazyVim formatting.lua 的 keymaps
    vim.keymap.set({ "n", "x" }, "<leader>cF", function()
      require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
    end, { desc = "Format Injected Langs", silent = true })
  end,
}
