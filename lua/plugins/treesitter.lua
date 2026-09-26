-- treesitter 域：nvim-treesitter（main 分支）+ textobjects + autotag。
-- 行为源：LazyVim plugins/treesitter.lua。
-- 差异：LazyVim.treesitter.* → meow.treesitter.*；build 事件（lazy 专用）改为
-- 启动时缺啥装啥；LazyVim.error → meow.error。
return {
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    name = "nvim-treesitter",
    config = function()
      local meow = require("meow")
      local TS = require("nvim-treesitter")

      if not TS.get_installed then
        return meow.error("请重启并运行 :TSUpdate 以使用 nvim-treesitter main 分支")
      end

      local opts = {
        indent = { enable = true },
        highlight = { enable = true },
        folds = { enable = true },
        ensure_installed = {
          "bash",
          "c",
          "diff",
          "html",
          "javascript",
          "jsdoc",
          "json",
          "lua",
          "luadoc",
          "luap",
          "markdown",
          "markdown_inline",
          "printf",
          "python",
          "query",
          "regex",
          "toml",
          "tsx",
          "typescript",
          "vim",
          "vimdoc",
          "xml",
          "yaml",
        },
      }

      TS.setup(opts)
      meow.treesitter.get_installed(true) -- initialize the installed langs

      -- 安装缺失 parser（LazyVim build 钩子的等效：启动时检查）
      local install = vim.tbl_filter(function(lang)
        return not meow.treesitter.have(lang)
      end, opts.ensure_installed or {})
      if #install > 0 then
        meow.treesitter.build(function()
          TS.install(install, { summary = true }):await(function()
            meow.treesitter.get_installed(true)
          end)
        end)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("meow_treesitter", { clear = true }),
        callback = function(ev)
          local ft, lang = ev.match, vim.treesitter.language.get_lang(ev.match)
          if not meow.treesitter.have(ft) then
            return
          end

          ---@param feat string
          ---@param query string
          local function enabled(feat, query)
            local f = opts[feat] or {}
            return f.enable ~= false
              and not (type(f.disable) == "table" and vim.tbl_contains(f.disable, lang))
              and meow.treesitter.have(ft, query)
          end

          -- highlighting
          if enabled("highlight", "highlights") then
            pcall(vim.treesitter.start, ev.buf)
          end

          -- indents
          if enabled("indent", "indents") then
            meow.set_default("indentexpr", "v:lua.require('meow.treesitter').indentexpr()")
          end

          -- folds
          if enabled("folds", "folds") then
            if meow.set_default("foldmethod", "expr") then
              meow.set_default("foldexpr", "v:lua.require('meow.treesitter').foldexpr()")
            end
          end
        end,
      })
    end,
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
    name = "nvim-treesitter-textobjects",
    config = function()
      local meow = require("meow")
      local opts = {
        move = {
          enable = true,
          set_jumps = true,
          -- LazyVim 扩展：buffer-local keymaps
          keys = {
            goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
            goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
            goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
            goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
          },
        },
      }
      local TS = require("nvim-treesitter-textobjects")
      if not TS.setup then
        return meow.error("请更新 nvim-treesitter-textobjects")
      end
      TS.setup(opts)

      local function attach(buf)
        local ft = vim.bo[buf].filetype
        if not (vim.tbl_get(opts, "move", "enable") and meow.treesitter.have(ft, "textobjects")) then
          return
        end
        ---@type table<string, table<string, string>>
        local moves = vim.tbl_get(opts, "move", "keys") or {}

        for method, keymaps in pairs(moves) do
          for key, query in pairs(keymaps) do
            local queries = type(query) == "table" and query or { query }
            local parts = {}
            for _, q in ipairs(queries) do
              local part = q:gsub("@", ""):gsub("%..*", "")
              part = part:sub(1, 1):upper() .. part:sub(2)
              table.insert(parts, part)
            end
            local desc = table.concat(parts, " or ")
            desc = (key:sub(1, 1) == "[" and "Prev " or "Next ") .. desc
            desc = desc .. (key:sub(2, 2) == key:sub(2, 2):upper() and " End" or " Start")
            vim.keymap.set({ "n", "x", "o" }, key, function()
              if vim.wo.diff and key:find("[cC]") then
                return vim.cmd("normal! " .. key)
              end
              require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
            end, {
              buffer = buf,
              desc = desc,
              silent = true,
            })
          end
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("meow_treesitter_textobjects", { clear = true }),
        callback = function(ev)
          attach(ev.buf)
        end,
      })
      vim.tbl_map(attach, vim.api.nvim_list_bufs())
    end,
  },
  {
    src = "https://github.com/windwp/nvim-ts-autotag",
    name = "nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup({})
    end,
  },
}
