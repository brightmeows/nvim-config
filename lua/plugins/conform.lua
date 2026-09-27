-- conform：格式化。行为源：LazyVim plugins/formatting.lua 的 spec 形态
-- （dependencies/lazy/cmd/keys/init 全镜像；注册段走 User VeryLazy，
-- 与基线 on_very_lazy 等价——init 在启动期执行，注册早于任何触发）。
return {
  "https://github.com/stevearc/conform.nvim",
  dependencies = { "mason.nvim" },
  lazy = true,
  cmd = "ConformInfo",
  -- stylua: ignore
  keys = {
    {
      "<leader>cF",
      function()
        require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
      end,
      mode = { "n", "x" },
      desc = "Format Injected Langs",
    },
  },
  init = function()
    -- 注册进 meow.format（行为源：LazyVim formatting.lua 的 on_very_lazy 段；
    -- 闭包在调用时按需 require，require 会触发 conform 加载）
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      once = true,
      callback = function()
        require("meow.format").register({
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
      end,
    })
  end,
  config = function()
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
  end,
}
