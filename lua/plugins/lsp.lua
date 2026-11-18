-- LSP 域：mason + mason-lspconfig + nvim-lspconfig。
-- 行为源：LazyVim plugins/lsp/init.lua 的 spec 结构——nvim-lspconfig 挂
-- BufReadPre/BufNewFile 事件、dependencies 带 mason 与 mason-lspconfig
--（占位空 config，setup 由本文件 lspconfig 段调用），mason 挂 cmd/keys/build；
-- mason 安装成功后的 FileType 重触发恢复（懒加载专用，行为源同款）。
-- 差异：servers 表是默认候选集（automatic_enable=false；lua_ls 始终启用，
-- 其余按 cmd 可用性过滤）；<leader>cl 全局化并加启停面板。

-- cmd 为函数的 server（如 ts_ls）静态判断不了可执行文件，按可用处理；
-- 只过滤 cmd 为表的 server。缺件时 Neovim 静默不启动，由 picker 的
-- installed 列提示。

---@param name string
local function cmd_available(name)
  local ok, config = pcall(function()
    return vim.lsp.config[name]
  end)
  if not ok then
    return true
  end
  local cmd = (config or {}).cmd
  if type(cmd) == "table" then
    return cmd[1] ~= nil and vim.fn.executable(cmd[1]) == 1
  end
  return true
end

---@param picker snacks.Picker
---@param item? snacks.picker.lsp.config.Item
local function lsp_toggle(picker, item)
  if not item then
    return
  end
  local enable = not vim.lsp.is_enabled(item.name)
  if enable and not cmd_available(item.name) then
    Snacks.notify.warn(("`%s` 的可执行文件不在 PATH，启动会失败。"):format(item.name))
    return
  end
  local ok, err = pcall(vim.lsp.enable, item.name, enable)
  if not ok then
    Snacks.notify.error(("`%s` 启用失败：%s"):format(item.name, err))
    return
  end
  picker:refresh()
end

---@param picker snacks.Picker
---@param item? snacks.picker.lsp.config.Item
local function lsp_restart(picker, item)
  if not item then
    return
  end
  if #vim.lsp.get_clients({ name = item.name }) == 0 then
    Snacks.notify.warn(("`%s` 没有活动 client。"):format(item.name))
    return
  end
  vim.cmd("lsp restart " .. vim.fn.fnameescape(item.name))
  picker:refresh()
end

local function lsp_manage()
  vim.schedule(function()
    Snacks.picker.lsp_config({
      actions = {
        lsp_toggle = lsp_toggle,
        lsp_restart = lsp_restart,
      },
      win = {
        input = {
          keys = {
            ["<c-t>"] = { "lsp_toggle", mode = { "n", "i" }, desc = "Toggle LSP" },
            ["<c-r>"] = { "lsp_restart", mode = { "n", "i" }, desc = "Restart LSP" },
          },
        },
        list = {
          keys = {
            ["<c-t>"] = { "lsp_toggle", mode = { "n" }, desc = "Toggle LSP" },
            ["<c-r>"] = { "lsp_restart", mode = { "n" }, desc = "Restart LSP" },
          },
        },
      },
    })
  end)
end

-- 启动期就注册，空 buffer 也能用；首次触发时按需拉起 nvim-lspconfig。
vim.keymap.set("n", "<leader>cl", function()
  require("lazy").load({ plugins = { "nvim-lspconfig" } })
  lsp_manage()
end, { desc = "Lsp Info", silent = true })

return {
  {
    "https://github.com/mason-org/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      ensure_installed = { "stylua", "shfmt" },
    },
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      -- mason 安装成功后重触发 FileType（行为源：LazyVim 同款，
      -- 让新装的 server 在懒加载下立即可用）
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)
      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
  {
    "https://github.com/neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      { "mason-org/mason-lspconfig.nvim", config = function() end },
    },
    config = function()
      local meow = require("meow")

      -- options for vim.diagnostic.config()（LazyVim 同款）
      local diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "●",
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = meow.icons.diagnostics.Error,
            [vim.diagnostic.severity.WARN] = meow.icons.diagnostics.Warn,
            [vim.diagnostic.severity.HINT] = meow.icons.diagnostics.Hint,
            [vim.diagnostic.severity.INFO] = meow.icons.diagnostics.Info,
          },
        },
      }
      vim.diagnostic.config(vim.deepcopy(diagnostics))

      -- LSP server 公共键位：gd/grr/gI/gy 由 snacks picker 提供，这里只留 gD 与其余公共键
      local server_keys = {
        { "gD", vim.lsp.buf.declaration, desc = "Goto Declaration", has = "declaration" },
        {
          "K",
          function()
            return vim.lsp.buf.hover()
          end,
          desc = "Hover",
        },
        {
          "gK",
          function()
            return vim.lsp.buf.signature_help()
          end,
          desc = "Signature Help",
          has = "signatureHelp",
        },
        {
          "<c-k>",
          function()
            return vim.lsp.buf.signature_help()
          end,
          mode = "i",
          desc = "Signature Help",
          has = "signatureHelp",
        },
        { "<leader>ca", vim.lsp.buf.code_action, desc = "Code Action", mode = { "n", "x" }, has = "codeAction" },
        { "<leader>cc", vim.lsp.codelens.run, desc = "Run Codelens", mode = { "n", "x" }, has = "codeLens" },
        { "<leader>cC", vim.lsp.codelens.refresh, desc = "Refresh & Display Codelens", mode = "n", has = "codeLens" },
        {
          "<leader>cR",
          function()
            Snacks.rename.rename_file()
          end,
          desc = "Rename File",
          mode = "n",
          has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
        },
        { "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" },
        { "<leader>cA", meow.lsp.action["source"], desc = "Source Action", has = "codeAction" },
        {
          "]]",
          function()
            Snacks.words.jump(vim.v.count1)
          end,
          has = "documentHighlight",
          desc = "Next Reference",
          enabled = function()
            return Snacks.words.is_enabled()
          end,
        },
        {
          "[[",
          function()
            Snacks.words.jump(-vim.v.count1)
          end,
          has = "documentHighlight",
          desc = "Prev Reference",
          enabled = function()
            return Snacks.words.is_enabled()
          end,
        },
        {
          "<a-n>",
          function()
            Snacks.words.jump(vim.v.count1, true)
          end,
          has = "documentHighlight",
          desc = "Next Reference",
          enabled = function()
            return Snacks.words.is_enabled()
          end,
        },
        {
          "<a-p>",
          function()
            Snacks.words.jump(-vim.v.count1, true)
          end,
          has = "documentHighlight",
          desc = "Prev Reference",
          enabled = function()
            return Snacks.words.is_enabled()
          end,
        },
        {
          "<leader>co",
          meow.lsp.action["source.organizeImports"],
          desc = "Organize Imports",
          has = "codeAction",
          enabled = function(buf)
            local code_actions = vim.tbl_filter(function(action)
              return action:find("^source%.organizeImports%.?$")
            end, meow.lsp.code_actions({ bufnr = buf }))
            return #code_actions > 0
          end,
        },
      }
      -- has → Snacks.keymap 的 lsp filter（method 条件），与 LazyVim 的
      -- lazyvim.plugins.lsp.keymaps.set 等效
      for _, k in ipairs(server_keys) do
        local has = k.has
        local method = nil
        if type(has) == "string" then
          method = has:find("/") and has or ("textDocument/" .. has)
        elseif type(has) == "table" then
          -- 多条件：取首（LazyVim 语义为逐 method 过滤，Snacks filter 单 method；
          -- 实测基线这些键在 lua_ls 下均可用，取首项覆盖主路径）
          method = has[1]:find("/") and has[1] or ("textDocument/" .. has[1])
        end
        Snacks.keymap.set(k.mode or "n", k[1], k[2], {
          desc = k.desc,
          nowait = k.nowait,
          silent = true,
          enabled = k.enabled,
          lsp = { method = method },
        })
      end

      vim.lsp.config("*", {
        capabilities = {
          workspace = {
            fileOperations = {
              didRename = true,
              willRename = true,
            },
          },
        },
      })

      -- 逐 server 配置：servers 表是默认候选集，lua_ls 始终启用，其余按可用性过滤
      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              codeLens = { enable = true },
              completion = { callSnippet = "Replace" },
              doc = { privateName = { "^_" } },
              hint = {
                enable = true,
                setType = false,
                paramType = true,
                paramName = "Disable",
                semicolon = "Disable",
                arrayIndex = "Disable",
              },
            },
          },
        },
        rust_analyzer = {},
        clangd = {},
        ts_ls = {},
        bashls = {},
        marksman = {},
      }

      for server, sopts in pairs(servers) do
        vim.lsp.config(server, sopts)
        if server == "lua_ls" or cmd_available(server) then
          vim.lsp.enable(server)
        end
      end

      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls" },
        automatic_enable = false,
      })

      -- inlay hints（LazyVim：Snacks.util.lsp.on 按能力触发）
      Snacks.util.lsp.on({ method = "textDocument/inlayHint" }, function(buffer)
        if
          vim.api.nvim_buf_is_valid(buffer)
          and vim.bo[buffer].buftype == ""
          and not vim.tbl_contains({ "vue" }, vim.bo[buffer].filetype)
        then
          vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
        end
      end)

      -- folds（LazyVim 同款：foldingRange 能力触发 foldexpr）
      Snacks.util.lsp.on({ method = "textDocument/foldingRange" }, function()
        if meow.set_default("foldmethod", "expr") then
          meow.set_default("foldexpr", "v:lua.vim.lsp.foldexpr()")
        end
      end)

      -- LSP 格式化注册进 meow.format（LazyVim：LazyVim.format.register(LazyVim.lsp.formatter())）
      meow.format.register(meow.lsp.formatter())
    end,
  },
}
