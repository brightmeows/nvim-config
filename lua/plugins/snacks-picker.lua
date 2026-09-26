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

    -- stylua: ignore
    map("<leader>,", function() Snacks.picker.buffers() end, "Buffers")
    -- stylua: ignore
    map("<leader>/", pick("grep"), "Grep (Root Dir)")
    -- stylua: ignore
    map("<leader>:", function() Snacks.picker.command_history() end, "Command History")
    -- stylua: ignore
    map("<leader><space>", pick("files"), "Find Files (Root Dir)")
    -- stylua: ignore
    map("<leader>n", function()
      if Snacks.config.picker and Snacks.config.picker.enabled then
        Snacks.picker.notifications()
      else
        Snacks.notifier.show_history()
      end
    end, "Notification History")
    -- find
    -- stylua: ignore
    map("<leader>fb", function() Snacks.picker.buffers() end, "Buffers")
    -- stylua: ignore
    map("<leader>fB", function() Snacks.picker.buffers({ hidden = true, nofile = true }) end, "Buffers (all)")
    -- stylua: ignore
    map("<leader>fc", pick.config_files(), "Find Config File")
    -- stylua: ignore
    map("<leader>ff", pick("files"), "Find Files (Root Dir)")
    -- stylua: ignore
    map("<leader>fF", pick("files", { root = false }), "Find Files (cwd)")
    -- stylua: ignore
    map("<leader>fg", function() Snacks.picker.git_files() end, "Find Files (git-files)")
    -- stylua: ignore
    map("<leader>fr", pick("oldfiles"), "Recent")
    -- stylua: ignore
    map("<leader>fR", function() Snacks.picker.recent({ filter = { cwd = true } }) end, "Recent (cwd)")
    -- stylua: ignore
    map("<leader>fp", function() Snacks.picker.projects() end, "Projects")
    -- git
    -- stylua: ignore
    map("<leader>gd", function() Snacks.picker.git_diff() end, "Git Diff (hunks)")
    -- stylua: ignore
    map("<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, "Git Diff (origin)")
    -- stylua: ignore
    map("<leader>gs", function() Snacks.picker.git_status() end, "Git Status")
    -- stylua: ignore
    map("<leader>gS", function() Snacks.picker.git_stash() end, "Git Stash")
    -- stylua: ignore
    map("<leader>gi", function() Snacks.picker.gh_issue() end, "GitHub Issues (open)")
    -- stylua: ignore
    map("<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, "GitHub Issues (all)")
    -- stylua: ignore
    map("<leader>gp", function() Snacks.picker.gh_pr() end, "GitHub Pull Requests (open)")
    -- stylua: ignore
    map("<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, "GitHub Pull Requests (all)")
    -- Grep
    -- stylua: ignore
    map("<leader>sb", function() Snacks.picker.lines() end, "Buffer Lines")
    -- stylua: ignore
    map("<leader>sB", function() Snacks.picker.grep_buffers() end, "Grep Open Buffers")
    -- stylua: ignore
    map("<leader>sg", pick("live_grep"), "Grep (Root Dir)")
    -- stylua: ignore
    map("<leader>sG", pick("live_grep", { root = false }), "Grep (cwd)")
    -- stylua: ignore
    map("<leader>sp", function()
      -- 原为 Snacks.picker.lazy()（搜索 lazy spec）；无 lazy.nvim，
      -- 改搜本配置的插件 spec 文件（等效入口）
      Snacks.picker.grep({ cwd = vim.fn.stdpath("config") .. "/lua/plugins" })
    end, "Search for Plugin Spec")
    -- stylua: ignore
    map("<leader>sw", pick("grep_word"), "Visual selection or word (Root Dir)", { "n", "x" })
    -- stylua: ignore
    map("<leader>sW", pick("grep_word", { root = false }), "Visual selection or word (cwd)", { "n", "x" })
    -- search
    -- stylua: ignore
    map('<leader>s"', function() Snacks.picker.registers() end, "Registers")
    -- stylua: ignore
    map("<leader>s/", function() Snacks.picker.search_history() end, "Search History")
    -- stylua: ignore
    map("<leader>sa", function() Snacks.picker.autocmds() end, "Autocmds")
    -- stylua: ignore
    map("<leader>sc", function() Snacks.picker.command_history() end, "Command History")
    -- stylua: ignore
    map("<leader>sC", function() Snacks.picker.commands() end, "Commands")
    -- stylua: ignore
    map("<leader>sd", function() Snacks.picker.diagnostics() end, "Diagnostics")
    -- stylua: ignore
    map("<leader>sD", function() Snacks.picker.diagnostics_buffer() end, "Buffer Diagnostics")
    -- stylua: ignore
    map("<leader>sh", function() Snacks.picker.help() end, "Help Pages")
    -- stylua: ignore
    map("<leader>sH", function() Snacks.picker.highlights() end, "Highlights")
    -- stylua: ignore
    map("<leader>si", function() Snacks.picker.icons() end, "Icons")
    -- stylua: ignore
    map("<leader>sj", function() Snacks.picker.jumps() end, "Jumps")
    -- stylua: ignore
    map("<leader>sk", function() Snacks.picker.keymaps() end, "Keymaps")
    -- stylua: ignore
    map("<leader>sl", function() Snacks.picker.loclist() end, "Location List")
    -- stylua: ignore
    map("<leader>sM", function() Snacks.picker.man() end, "Man Pages")
    -- stylua: ignore
    map("<leader>sm", function() Snacks.picker.marks() end, "Marks")
    -- stylua: ignore
    map("<leader>sR", function() Snacks.picker.resume() end, "Resume")
    -- stylua: ignore
    map("<leader>sq", function() Snacks.picker.qflist() end, "Quickfix List")
    -- stylua: ignore
    map("<leader>su", function() Snacks.picker.undo() end, "Undotree")
    -- ui
    -- stylua: ignore
    map("<leader>uC", function() Snacks.picker.colorschemes() end, "Colorschemes")
    -- stylua: ignore
    map("<leader>st", function() Snacks.picker.todo_comments() end, "Todo")
    -- stylua: ignore
    map("<leader>sT", function() Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } }) end, "Todo/Fix/Fixme")

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
