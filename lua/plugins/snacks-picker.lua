-- snacks picker 键位（<leader>f/g/s 组）。行为源：LazyVim extras/editor/snacks_picker.lua
-- 的 keys 表与 lspconfig servers["*"].keys 覆盖（基线真值：picker 版本胜出）。
-- LazyVim.pick.* → meow.pick；无插件文件本体，仅键位——以虚拟 spec 挂在 snacks 之后。
return {
  src = "https://github.com/folke/snacks.nvim",
  name = "snacks.nvim", -- 与 snacks.lua 同源：vim.pack.add 对同名同 src 重复 add 无副作用，
  -- 此文件只注册键位，不重复 setup。
  config = function()
    local pick = require("meow.pick")
    -- 注册 picker（行为源：snacks_picker extra 的 LazyVim.pick.register 调用）
    pick.register({
      name = "snacks",
      commands = {
        files = "files",
        live_grep = "grep",
        oldfiles = "recent",
      },
      open = function(source, opts)
        return Snacks.picker.pick(source, opts)
      end,
    })
    local function map(lhs, rhs, desc, mode)
      vim.keymap.set(mode or "n", lhs, rhs, { desc = desc, silent = true })
    end

    map("<leader>,", function()
      Snacks.picker.buffers()
    end, "Buffers")
    map("<leader>/", pick("grep"), "Grep (Root Dir)")
    map("<leader>:", function()
      Snacks.picker.command_history()
    end, "Command History")
    map("<leader><space>", pick("files"), "Find Files (Root Dir)")
    map("<leader>n", function()
      if Snacks.config.picker and Snacks.config.picker.enabled then
        Snacks.picker.notifications()
      else
        Snacks.notifier.show_history()
      end
    end, "Notification History")
    -- find
    map("<leader>fb", function()
      Snacks.picker.buffers()
    end, "Buffers")
    map("<leader>fB", function()
      Snacks.picker.buffers({ hidden = true, nofile = true })
    end, "Buffers (all)")
    map("<leader>fc", pick.config_files(), "Find Config File")
    map("<leader>ff", pick("files"), "Find Files (Root Dir)")
    map("<leader>fF", pick("files", { root = false }), "Find Files (cwd)")
    map("<leader>fg", function()
      Snacks.picker.git_files()
    end, "Find Files (git-files)")
    map("<leader>fr", pick("oldfiles"), "Recent")
    map("<leader>fR", function()
      Snacks.picker.recent({ filter = { cwd = true } })
    end, "Recent (cwd)")
    map("<leader>fp", function()
      Snacks.picker.projects()
    end, "Projects")
    -- git
    map("<leader>gd", function()
      Snacks.picker.git_diff()
    end, "Git Diff (hunks)")
    map("<leader>gD", function()
      Snacks.picker.git_diff({ base = "origin", group = true })
    end, "Git Diff (origin)")
    map("<leader>gs", function()
      Snacks.picker.git_status()
    end, "Git Status")
    map("<leader>gS", function()
      Snacks.picker.git_stash()
    end, "Git Stash")
    map("<leader>gi", function()
      Snacks.picker.gh_issue()
    end, "GitHub Issues (open)")
    map("<leader>gI", function()
      Snacks.picker.gh_issue({ state = "all" })
    end, "GitHub Issues (all)")
    map("<leader>gp", function()
      Snacks.picker.gh_pr()
    end, "GitHub Pull Requests (open)")
    map("<leader>gP", function()
      Snacks.picker.gh_pr({ state = "all" })
    end, "GitHub Pull Requests (all)")
    -- Grep
    map("<leader>sb", function()
      Snacks.picker.lines()
    end, "Buffer Lines")
    map("<leader>sB", function()
      Snacks.picker.grep_buffers()
    end, "Grep Open Buffers")
    map("<leader>sg", pick("live_grep"), "Grep (Root Dir)")
    map("<leader>sG", pick("live_grep", { root = false }), "Grep (cwd)")
    map("<leader>sp", function()
      -- 原为 Snacks.picker.lazy()（搜索 lazy spec）；无 lazy.nvim，
      -- 改搜本配置的插件 spec 文件（等效入口）
      Snacks.picker.grep({ cwd = vim.fn.stdpath("config") .. "/lua/plugins" })
    end, "Search for Plugin Spec")
    map("<leader>sw", pick("grep_word"), "Visual selection or word (Root Dir)", { "n", "x" })
    map("<leader>sW", pick("grep_word", { root = false }), "Visual selection or word (cwd)", { "n", "x" })
    -- search
    map('<leader>s"', function()
      Snacks.picker.registers()
    end, "Registers")
    map("<leader>s/", function()
      Snacks.picker.search_history()
    end, "Search History")
    map("<leader>sa", function()
      Snacks.picker.autocmds()
    end, "Autocmds")
    map("<leader>sc", function()
      Snacks.picker.command_history()
    end, "Command History")
    map("<leader>sC", function()
      Snacks.picker.commands()
    end, "Commands")
    map("<leader>sd", function()
      Snacks.picker.diagnostics()
    end, "Diagnostics")
    map("<leader>sD", function()
      Snacks.picker.diagnostics_buffer()
    end, "Buffer Diagnostics")
    map("<leader>sh", function()
      Snacks.picker.help()
    end, "Help Pages")
    map("<leader>sH", function()
      Snacks.picker.highlights()
    end, "Highlights")
    map("<leader>si", function()
      Snacks.picker.icons()
    end, "Icons")
    map("<leader>sj", function()
      Snacks.picker.jumps()
    end, "Jumps")
    map("<leader>sk", function()
      Snacks.picker.keymaps()
    end, "Keymaps")
    map("<leader>sl", function()
      Snacks.picker.loclist()
    end, "Location List")
    map("<leader>sM", function()
      Snacks.picker.man()
    end, "Man Pages")
    map("<leader>sm", function()
      Snacks.picker.marks()
    end, "Marks")
    map("<leader>sR", function()
      Snacks.picker.resume()
    end, "Resume")
    map("<leader>sq", function()
      Snacks.picker.qflist()
    end, "Quickfix List")
    map("<leader>su", function()
      Snacks.picker.undo()
    end, "Undotree")
    -- ui
    map("<leader>uC", function()
      Snacks.picker.colorschemes()
    end, "Colorschemes")
    map("<leader>st", function()
      Snacks.picker.todo_comments()
    end, "Todo")
    map("<leader>sT", function()
      Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
    end, "Todo/Fix/Fixme")

    -- snacks_picker extra 的 lspconfig 键位（基线真值：picker 版本胜出，gd/gr/gI/gy 走 picker）
    -- 含 has 能力条件——用 Snacks.keymap 的 lsp filter 实现
    local lsp_keys = {
      {
        "gd",
        function()
          Snacks.picker.lsp_definitions()
        end,
        desc = "Goto Definition",
        has = "definition",
      },
      {
        "gr",
        function()
          Snacks.picker.lsp_references()
        end,
        nowait = true,
        desc = "References",
      },
      {
        "gI",
        function()
          Snacks.picker.lsp_implementations()
        end,
        desc = "Goto Implementation",
      },
      {
        "gy",
        function()
          Snacks.picker.lsp_type_definitions()
        end,
        desc = "Goto T[y]pe Definition",
      },
      {
        "<leader>ss",
        function()
          Snacks.picker.lsp_symbols({ filter = require("meow").kind_filter })
        end,
        desc = "LSP Symbols",
        has = "documentSymbol",
      },
      {
        "<leader>sS",
        function()
          Snacks.picker.lsp_workspace_symbols({ filter = require("meow").kind_filter })
        end,
        desc = "LSP Workspace Symbols",
        has = "workspace/symbols",
      },
      {
        "gai",
        function()
          Snacks.picker.lsp_incoming_calls()
        end,
        desc = "C[a]lls Incoming",
        has = "callHierarchy/incomingCalls",
      },
      {
        "gao",
        function()
          Snacks.picker.lsp_outgoing_calls()
        end,
        desc = "C[a]lls Outgoing",
        has = "callHierarchy/outgoingCalls",
      },
    }
    for _, k in ipairs(lsp_keys) do
      Snacks.keymap.set("n", k[1], k[2], {
        desc = k.desc,
        nowait = k.nowait,
        silent = true,
        lsp = { method = k.has and ("textDocument/" .. k.has) or nil },
      })
    end
  end,
}
