-- blink.cmp：补全。行为源：LazyVim extras/coding/blink.lua。
-- 差异：LazyVim.cmp.* → meow.cmp.*；kind_icons 走 meow.icons；
-- catppuccin 的 blink_cmp 集成并入主题文件。
-- blink 版本：基线锁 main 分支 commit（vim.pack 默认分支同）。
return {
  {
    src = "https://github.com/saghen/blink.cmp",
    name = "blink.cmp",
    -- 钉在基线 lazy-lock 的 tag（v1.10.2）：v2 主分支需要额外的 blink.lib 包，
    -- 属 breaking 依赖变更，零感知迁移不随上游升级。
    version = "v1.10.2",
    config = function()
      local meow = require("meow")
      ---@type blink.cmp.Config
      local opts = {
        snippets = {
          preset = "default",
          expand = function(snippet)
            meow.cmp.expand(snippet)
          end,
        },
        appearance = {
          use_nvim_cmp_as_default = false,
          nerd_font_variant = "mono",
          kind_icons = vim.tbl_extend("force", {}, meow.icons.kinds),
        },
        completion = {
          accept = {
            auto_brackets = { enabled = true },
          },
          menu = {
            draw = { treesitter = { "lsp" } },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
          },
          ghost_text = {
            enabled = vim.g.ai_cmp,
          },
        },
        sources = {
          compat = {},
          default = { "lsp", "path", "snippets", "buffer" },
          per_filetype = {
            lua = { inherit_defaults = true, "lazydev" },
          },
          providers = {
            lazydev = {
              name = "LazyDev",
              module = "lazydev.integrations.blink",
              score_offset = 100,
            },
          },
        },
        cmdline = {
          enabled = true,
          keymap = {
            preset = "cmdline",
            ["<Right>"] = false,
            ["<Left>"] = false,
          },
          completion = {
            list = { selection = { preselect = false } },
            menu = {
              auto_show = function(ctx)
                return vim.fn.getcmdtype() == ":"
              end,
            },
            ghost_text = { enabled = true },
          },
        },
        keymap = {
          preset = "enter",
          ["<C-y>"] = { "select_and_accept" },
        },
      }

      -- Tab 键：snippet 前进 fallback（LazyVim cmp.map 同款，去掉 ai_nes/ai_accept——
      -- 本配置无 AI inline suggestion 来源）
      if not opts.keymap["<Tab>"] then
        opts.keymap["<Tab>"] = {
          meow.cmp.map({ "snippet_forward" }),
          "fallback",
        }
      end

      require("blink.cmp").setup(opts)
    end,
  },
  {
    src = "https://github.com/rafamadriz/friendly-snippets",
    name = "friendly-snippets",
    -- 片段库由 blink 的 snippets preset 自动从 rtp 读取，无需 config
  },
}
