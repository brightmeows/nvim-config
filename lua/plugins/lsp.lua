-- LSP 域：mason + mason-lspconfig + nvim-lspconfig。
-- 行为源：LazyVim plugins/lsp/init.lua 的 spec 结构——nvim-lspconfig 挂
-- BufReadPre/BufNewFile 事件、dependencies 带 mason 与 mason-lspconfig
--（占位空 config，setup 由本文件 lspconfig 段调用），mason 挂 cmd/keys/build；
-- mason 安装成功后的 FileType 重触发恢复（懒加载专用，行为源同款）。
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

      -- LSP server 公共配置：capabilities + 键位（snacks_picker extra 版本——基线真值）
      local server_keys = {
        {
          "<leader>cl",
          function()
            Snacks.picker.lsp_config()
          end,
          desc = "Lsp Info",
        },
        { "gd", vim.lsp.buf.definition, desc = "Goto Definition", has = "definition" },
        { "gr", vim.lsp.buf.references, desc = "References", nowait = true },
        { "gI", vim.lsp.buf.implementation, desc = "Goto Implementation" },
        { "gy", vim.lsp.buf.type_definition, desc = "Goto T[y]pe Definition" },
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

      -- 逐 server 配置（LazyVim configure() 同语义）
      local servers = {
        stylua = { enabled = false },
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
      }

      local mason_all = {}
      local mason_exclude = {}
      local ok_mason_lspconfig, mason_map = pcall(function()
        return require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
      end)
      if ok_mason_lspconfig then
        mason_all = vim.tbl_keys(mason_map)
      end

      local install = {}
      for server, sopts in pairs(servers) do
        if sopts.enabled == false then
          mason_exclude[#mason_exclude + 1] = server
        else
          vim.lsp.config(server, sopts)
          local use_mason = vim.tbl_contains(mason_all, server)
          if not use_mason then
            vim.lsp.enable(server)
          end
          install[#install + 1] = server
        end
      end
      -- stylua 从 servers 表排除但仍由 mason 保证安装（LazyVim 语义）
      vim.list_extend(install, {})

      require("mason-lspconfig").setup({
        -- servers 表中走 mason 的 server（当前仅 lua_ls；stylua 已排除）
        ensure_installed = { "lua_ls" },
        automatic_enable = { exclude = mason_exclude },
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
