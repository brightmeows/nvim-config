-- outline.nvim：当前文件 LSP 符号大纲（自增功能）。
-- 形态对齐 LazyVim 16.0 的 editor.outline extra：<leader>cs 接管 trouble symbols，
-- 图标走 meow 的 kind 表，过滤沿用 kind_filter（保留 Field/Property 看类型形状）。
return {
  "https://github.com/hedyhli/outline.nvim",
  cmd = "Outline",
  keys = {
    { "<leader>cs", "<cmd>Outline<cr>", desc = "Toggle Outline" },
    { "<leader>cO", "<cmd>OutlineFocus<cr>", desc = "Focus Outline" },
  },
  opts = function()
    local defaults = require("outline.config").defaults
    local opts = {
      symbols = {
        icons = {},
        filter = vim.deepcopy(require("meow").kind_filter),
      },
      outline_items = {
        show_symbol_details = true,
      },
      -- 不抢焦点：代码窗口保持 current，LSP 晚到时 refresh/retry 才能更新。
      outline_window = {
        position = "right",
        focus_on_open = false,
      },
      keymaps = {
        up_and_jump = "<up>",
        down_and_jump = "<down>",
      },
    }

    for kind, symbol in pairs(defaults.symbols.icons) do
      opts.symbols.icons[kind] = {
        icon = require("meow").icons.kinds[kind] or symbol.icon,
        hl = symbol.hl,
      }
    end

    return opts
  end,
  config = function(_, opts)
    require("outline").setup(opts)

    -- outline 没有订阅 LspAttach：若打开时尚无 client，补一次只在无 provider 时的重试。
    local group = vim.api.nvim_create_augroup("meow_outline_lsp_attach", { clear = true })
    vim.api.nvim_create_autocmd("LspAttach", {
      group = group,
      callback = function(args)
        local ok, outline = pcall(require, "outline")
        if not ok then
          return
        end
        if type(outline._get_sidebar) ~= "function" or type(outline.refresh) ~= "function" then
          return
        end
        local sidebar = outline._get_sidebar()
        if not sidebar or not sidebar:is_open() or sidebar.code.buf ~= args.buf then
          return
        end
        outline.refresh()

        -- lua_ls 等 server 在 LspAttach 后仍可能没完成索引，补两次延迟重试。
        local function retry()
          local s = outline._get_sidebar()
          if s and s.view and s:is_open() and s.code.buf == args.buf and vim.api.nvim_get_current_buf() == args.buf then
            outline.refresh()
          end
        end
        vim.defer_fn(retry, 2000)
        vim.defer_fn(retry, 8000)
      end,
    })
  end,
}
