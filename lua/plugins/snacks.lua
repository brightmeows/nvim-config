-- snacks.nvim：LazyVim 的 UI 基础设施（dashboard/terminal/toggle/notifier/picker...）。
-- 行为源：LazyVim plugins/init.lua + plugins/util.lua + plugins/ui.lua +
-- extras/editor/snacks_picker.lua 的 opts 合并，叠加基线覆盖（scroll 动画关闭）。
-- 形态镜像 LazyVim：单 spec（priority=1000、lazy=false）；picker 键位合并进
-- keys 字段（原 snacks-picker.lua 删除，经 lazy keys handler 注册）；lsp 条件键
--（has 能力过滤）lazy keys 表达不了，留 config 走 Snacks.keymap 的 lsp filter。
local opts = {
  bigfile = { enabled = true },
  quickfile = { enabled = true },
  terminal = {
    win = {
      keys = {
        nav_h = {
          "<C-h>",
          function(self)
            if not self:is_floating() then
              return "<C-h>"
            end
            vim.schedule(function()
              vim.cmd.wincmd("h")
            end)
          end,
          desc = "Go to Left Window",
          expr = true,
          mode = "t",
        },
        nav_j = {
          "<C-j>",
          function(self)
            if not self:is_floating() then
              return "<C-j>"
            end
            vim.schedule(function()
              vim.cmd.wincmd("j")
            end)
          end,
          desc = "Go to Lower Window",
          expr = true,
          mode = "t",
        },
        nav_k = {
          "<C-k>",
          function(self)
            if not self:is_floating() then
              return "<C-k>"
            end
            vim.schedule(function()
              vim.cmd.wincmd("k")
            end)
          end,
          desc = "Go to Upper Window",
          expr = true,
          mode = "t",
        },
        nav_l = {
          "<C-l>",
          function(self)
            if not self:is_floating() then
              return "<C-l>"
            end
            vim.schedule(function()
              vim.cmd.wincmd("l")
            end)
          end,
          desc = "Go to Right Window",
          expr = true,
          mode = "t",
        },
        hide_slash = { "<C-/>", "hide", desc = "Hide Terminal", mode = "t" },
        hide_underscore = { "<c-_>", "hide", desc = "which_key_ignore", mode = "t" },
      },
    },
  },
  -- ui.lua
  indent = { enabled = true },
  input = { enabled = true },
  notifier = { enabled = true },
  scope = { enabled = true },
  -- 基线覆盖：snacks-animated-scrolling-off.lua 关闭滚动动画
  scroll = { enabled = false },
  -- LazyVim 用 options.lua 的 %!v:lua 表达式接管 statuscolumn，禁用 snacks 自设
  statuscolumn = { enabled = false },
  toggle = {
    map = function(modes, lhs, rhs, mapopts)
      require("meow").safe_keymap_set(modes, lhs, rhs, mapopts)
    end,
  },
  words = { enabled = true },
  -- picker（snacks_picker extra）：input 窗口键与 toggle_cwd 动作
  picker = {
    win = {
      input = {
        keys = {
          ["<a-c>"] = {
            "toggle_cwd",
            mode = { "n", "i" },
          },
          ["<a-t>"] = {
            "trouble_open",
            mode = { "n", "i" },
          },
        },
      },
    },
    actions = {
      toggle_cwd = function(p)
        local root = require("meow.root")({ buf = p.input.filter.current_buf, normalize = true })
        local cwd = vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
        local current = p:cwd()
        p:set_cwd(current == root and cwd or root)
        p:find()
      end,
      trouble_open = function(...)
        return require("trouble.sources.snacks").actions.trouble_open.action(...)
      end,
    },
  },
  -- dashboard（ui.lua + snacks_picker extra 的 Projects 项）
  dashboard = {
    preset = {
      pick = function(cmd, pickopts)
        return require("meow.pick")(cmd, pickopts)()
      end,
      header = [[
          ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
          ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z    
          ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z       
          ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z         
          ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║           
          ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝           
   ]],
      ---@type snacks.dashboard.Item[]
      keys = {
        { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
        { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
        { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
        {
          icon = " ",
          key = "c",
          desc = "Config",
          action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
        },
        { icon = " ", key = "s", desc = "Restore Session", section = "session" },
        { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
        {
          icon = "󰒲 ",
          key = "l",
          desc = "Update Plugins",
          action = ":Lazy",
        },
        { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
  },
}

return {
  "https://github.com/folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = opts,
  -- picker 键位（原 snacks-picker.lua 全量；<leader>n 与 config 内注册重复，留 config；
  -- <leader>sp 恢复基线 Snacks.picker.lazy()——lazy.nvim 回归后该入口重新有效）
  keys = function()
    local pick = require("meow.pick")
    local keys = {}
    ---@param mode? string|string[]
    local function add(lhs, rhs, desc, mode)
      keys[#keys + 1] = { lhs, rhs, desc = desc, mode = mode, silent = true }
    end

    add("<leader>,", function()
      Snacks.picker.buffers()
    end, "Buffers")
    add("<leader>/", pick("grep"), "Grep (Root Dir)")
    add("<leader>:", function()
      Snacks.picker.command_history()
    end, "Command History")
    add("<leader><space>", pick("files"), "Find Files (Root Dir)")
    -- find
    add("<leader>fb", function()
      Snacks.picker.buffers()
    end, "Buffers")
    add("<leader>fB", function()
      Snacks.picker.buffers({ hidden = true, nofile = true })
    end, "Buffers (all)")
    add("<leader>fc", pick.config_files(), "Find Config File")
    add("<leader>ff", pick("files"), "Find Files (Root Dir)")
    add("<leader>fF", pick("files", { root = false }), "Find Files (cwd)")
    add("<leader>fg", function()
      Snacks.picker.git_files()
    end, "Find Files (git-files)")
    add("<leader>fr", pick("oldfiles"), "Recent")
    add("<leader>fR", function()
      Snacks.picker.recent({ filter = { cwd = true } })
    end, "Recent (cwd)")
    add("<leader>fp", function()
      Snacks.picker.projects()
    end, "Projects")
    -- git
    add("<leader>gd", function()
      Snacks.picker.git_diff()
    end, "Git Diff (hunks)")
    add("<leader>gD", function()
      Snacks.picker.git_diff({ base = "origin", group = true })
    end, "Git Diff (origin)")
    add("<leader>gs", function()
      Snacks.picker.git_status()
    end, "Git Status")
    add("<leader>gS", function()
      Snacks.picker.git_stash()
    end, "Git Stash")
    add("<leader>gi", function()
      Snacks.picker.gh_issue()
    end, "GitHub Issues (open)")
    add("<leader>gI", function()
      Snacks.picker.gh_issue({ state = "all" })
    end, "GitHub Issues (all)")
    add("<leader>gp", function()
      Snacks.picker.gh_pr()
    end, "GitHub Pull Requests (open)")
    add("<leader>gP", function()
      Snacks.picker.gh_pr({ state = "all" })
    end, "GitHub Pull Requests (all)")
    -- Grep
    add("<leader>sb", function()
      Snacks.picker.lines()
    end, "Buffer Lines")
    add("<leader>sB", function()
      Snacks.picker.grep_buffers()
    end, "Grep Open Buffers")
    add("<leader>sg", pick("live_grep"), "Grep (Root Dir)")
    add("<leader>sG", pick("live_grep", { root = false }), "Grep (cwd)")
    add("<leader>sp", function()
      Snacks.picker.lazy()
    end, "Search for Plugin Spec")
    add("<leader>sw", pick("grep_word"), "Visual selection or word (Root Dir)", { "n", "x" })
    add("<leader>sW", pick("grep_word", { root = false }), "Visual selection or word (cwd)", { "n", "x" })
    -- search
    add('<leader>s"', function()
      Snacks.picker.registers()
    end, "Registers")
    add("<leader>s/", function()
      Snacks.picker.search_history()
    end, "Search History")
    add("<leader>sa", function()
      Snacks.picker.autocmds()
    end, "Autocmds")
    add("<leader>sc", function()
      Snacks.picker.command_history()
    end, "Command History")
    add("<leader>sC", function()
      Snacks.picker.commands()
    end, "Commands")
    add("<leader>sd", function()
      Snacks.picker.diagnostics()
    end, "Diagnostics")
    add("<leader>sD", function()
      Snacks.picker.diagnostics_buffer()
    end, "Buffer Diagnostics")
    add("<leader>sh", function()
      Snacks.picker.help()
    end, "Help Pages")
    add("<leader>sH", function()
      Snacks.picker.highlights()
    end, "Highlights")
    add("<leader>si", function()
      Snacks.picker.icons()
    end, "Icons")
    add("<leader>sj", function()
      Snacks.picker.jumps()
    end, "Jumps")
    add("<leader>sk", function()
      Snacks.picker.keymaps()
    end, "Keymaps")
    add("<leader>sl", function()
      Snacks.picker.loclist()
    end, "Location List")
    add("<leader>sM", function()
      Snacks.picker.man()
    end, "Man Pages")
    add("<leader>sm", function()
      Snacks.picker.marks()
    end, "Marks")
    add("<leader>sR", function()
      Snacks.picker.resume()
    end, "Resume")
    add("<leader>sq", function()
      Snacks.picker.qflist()
    end, "Quickfix List")
    add("<leader>su", function()
      Snacks.picker.undo()
    end, "Undotree")
    -- ui
    add("<leader>uC", function()
      Snacks.picker.colorschemes()
    end, "Colorschemes")
    add("<leader>st", function()
      Snacks.picker.todo_comments()
    end, "Todo")
    add("<leader>sT", function()
      Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
    end, "Todo/Fix/Fixme")
    return keys
  end,
  -- opts 走 chunk 级 upvalue（当前无其它 spec 片段向 snacks 叠 opts，与 lazy
  -- 合并结果同内容；日后若有片段叠 opts，config 需改回 function(_, opts)）
  config = function()
    local notify = vim.notify
    require("snacks").setup(opts)
    -- 恢复 vim.notify 让 noice 接管（LazyVim 同款 HACK，避免早期通知丢失）
    vim.notify = notify

    -- 注册 picker（行为源：snacks_picker extra 的 LazyVim.pick.register 调用）
    local pick = require("meow.pick")
    pick.register({
      name = "snacks",
      commands = {
        files = "files",
        live_grep = "grep",
        oldfiles = "recent",
      },
      open = function(source, o)
        return Snacks.picker.pick(source, o)
      end,
    })

    -- LazyVim util.lua 的 scratch keymaps 与 ui.lua 的通知键
    vim.keymap.set("n", "<leader>.", function()
      Snacks.scratch()
    end, { desc = "Toggle Scratch Buffer", silent = true })
    vim.keymap.set("n", "<leader>S", function()
      Snacks.scratch.select()
    end, { desc = "Select Scratch Buffer", silent = true })
    vim.keymap.set("n", "<leader>dps", function()
      Snacks.profiler.scratch()
    end, { desc = "Profiler Scratch Buffer", silent = true })
    vim.keymap.set("n", "<leader>n", function()
      if Snacks.config.picker and Snacks.config.picker.enabled then
        Snacks.picker.notifications()
      else
        Snacks.notifier.show_history()
      end
    end, { desc = "Notification History", silent = true })
    vim.keymap.set("n", "<leader>un", function()
      Snacks.notifier.hide()
    end, { desc = "Dismiss All Notifications", silent = true })

    -- snacks_picker extra 的 lspconfig 键位（基线真值：picker 版本胜出，gd/gr/gI/gy 走 picker）；
    -- 含 has 能力条件——用 Snacks.keymap 的 lsp filter 实现（lazy keys 表达不了 method 过滤）
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
