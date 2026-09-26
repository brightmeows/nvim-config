-- lualine：状态栏。行为源：LazyVim plugins/ui.lua 的 lualine spec。
-- 差异：LazyVim.lualine.* → meow.lualine.*；lazy.status 更新组件移除
-- （随 lazy.nvim 一并移除，vim.pack 无后台更新检查，无等效物）。
return {
  src = "https://github.com/nvim-lualine/lualine.nvim",
  name = "lualine.nvim",
  config = function()
    -- PERF: LazyVim 同款 lualine require 优化
    local lualine_require = require("lualine_require")
    lualine_require.require = require

    local meow = require("meow")
    local icons = meow.icons

    vim.g.lualine_laststatus = vim.g.lualine_laststatus or vim.o.laststatus
    vim.o.laststatus = vim.g.lualine_laststatus

    local opts = {
      options = {
        theme = "auto",
        globalstatus = vim.o.laststatus == 3,
        disabled_filetypes = { statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" } },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },

        lualine_c = {
          meow.lualine.root_dir(),
          {
            "diagnostics",
            symbols = {
              error = icons.diagnostics.Error,
              warn = icons.diagnostics.Warn,
              info = icons.diagnostics.Info,
              hint = icons.diagnostics.Hint,
            },
          },
          { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          { meow.lualine.pretty_path() },
        },
        lualine_x = {
          Snacks.profiler.status(),
          -- stylua: ignore
          {
            function() return require("noice").api.status.command.get() end,
            cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
            color = function() return { fg = Snacks.util.color("Statement") } end,
          },
          -- stylua: ignore
          {
            function() return require("noice").api.status.mode.get() end,
            cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
            color = function() return { fg = Snacks.util.color("Constant") } end,
          },
          -- stylua: ignore
          {
            function() return "  " .. require("dap").status() end,
            cond = function() return package.loaded["dap"] and require("dap").status() ~= "" end,
            color = function() return { fg = Snacks.util.color("Debug") } end,
          },
          -- 更新计数（基线 lazy.status 组件的等效复刻，数据来自 meow.packcheck）
          {
            function()
              return require("meow.packcheck").status()
            end,
            cond = function()
              return require("meow.packcheck").has_updates()
            end,
            color = function()
              return { fg = Snacks.util.color("Special") }
            end,
          },
          {
            "diff",
            symbols = {
              added = icons.git.added,
              modified = icons.git.modified,
              removed = icons.git.removed,
            },
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
          },
        },
        lualine_y = {
          { "progress", separator = " ", padding = { left = 1, right = 0 } },
          { "location", padding = { left = 0, right = 1 } },
        },
        lualine_z = {
          function()
            return " " .. os.date("%R")
          end,
        },
      },
      extensions = { "neo-tree", "fzf" },
    }

    -- trouble 文档符号（LazyVim：vim.g.trouble_lualine 开关）
    if vim.g.trouble_lualine then
      local ok, trouble = pcall(require, "trouble")
      if ok then
        local symbols = trouble.statusline({
          mode = "symbols",
          groups = {},
          title = false,
          filter = { range = true },
          format = "{kind_icon}{symbol.name:Normal}",
          hl_group = "lualine_c_normal",
        })
        table.insert(opts.sections.lualine_c, {
          symbols and symbols.get,
          cond = function()
            return vim.b.trouble_lualine ~= false and symbols.has()
          end,
        })
      end
    end

    require("lualine").setup(opts)
  end,
}
