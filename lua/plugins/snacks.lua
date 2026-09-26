-- snacks.nvim：LazyVim 的 UI 基础设施（dashboard/terminal/toggle/notifier/picker...）。
-- 行为源：LazyVim plugins/init.lua + plugins/util.lua + plugins/ui.lua + extras/editor/snacks_picker.lua
-- 的 snacks opts 合并，叠加基线覆盖（scroll 动画关闭）。
-- 无 lazy 事件，全部在启动时 setup（vim.pack 语义）。
local M = {}

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
    map = function(modes, lhs, rhs, opts)
      require("meow").safe_keymap_set(modes, lhs, rhs, opts)
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
      pick = function(cmd, opts)
        return require("meow.pick")(cmd, opts)()
      end,
      header = [[
          ██╗      █████╗ ███████╗██╗   ██╗██╗   ██╗██╗███╗   ███╗          Z
          ██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝██║   ██║██║████╗ ████║      Z    
          ██║     ███████║  ███╔╝  ╚████╔╝ ██║   ██║██║██╔████╔██║   z       
          ██║     ██╔══██║ ███╔╝    ╚██╔╝  ╚██╗ ██╔╝██║██║╚██╔╝██║ z         
          ███████╗██║  ██║███████╗   ██║    ╚████╔╝ ██║██║ ╚═╝ ██║           
          ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝     ╚═══╝  ╚═╝╚═╝     ╚═╝           
   ]],
      -- stylua: ignore
      ---@type snacks.dashboard.Item[]
      keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "p", desc = "Projects", action = ":lua Snacks.picker.projects()" },
          { icon = "󰒲 ", key = "l", desc = "Update Plugins", action = function()
            -- 下载阶段无内建可见反馈（进度只进 messages 且被 dashboard
            -- 盖住），先给出即时提示避免“按下无反应”观感；确认页打开后
            -- 由 config/autocmds.lua 的 nvim-pack FileType 提示操作方式。
            vim.notify("检查插件更新中…稍后打开确认页", vim.log.levels.INFO, { title = "vim.pack" })
            vim.pack.update()
          end },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
      },
    },
  },
}

return {
  src = "https://github.com/folke/snacks.nvim",
  name = "snacks.nvim",
  config = function()
    local notify = vim.notify
    require("snacks").setup(opts)
    -- 恢复 vim.notify 让 noice 接管（LazyVim 同款 HACK，避免早期通知丢失）
    vim.notify = notify

    -- LazyVim util.lua 的 scratch keymaps 与 ui.lua 的通知键
    -- stylua: ignore
    vim.keymap.set("n", "<leader>.", function() Snacks.scratch() end, { desc = "Toggle Scratch Buffer", silent = true })
    -- stylua: ignore
    vim.keymap.set("n", "<leader>S", function() Snacks.scratch.select() end, { desc = "Select Scratch Buffer", silent = true })
    -- stylua: ignore
    vim.keymap.set("n", "<leader>dps", function() Snacks.profiler.scratch() end, { desc = "Profiler Scratch Buffer", silent = true })
    -- stylua: ignore
    vim.keymap.set("n", "<leader>n", function()
      if Snacks.config.picker and Snacks.config.picker.enabled then
        Snacks.picker.notifications()
      else
        Snacks.notifier.show_history()
      end
    end, { desc = "Notification History", silent = true })
    -- stylua: ignore
    vim.keymap.set("n", "<leader>un", function() Snacks.notifier.hide() end, { desc = "Dismiss All Notifications", silent = true })
  end,
}
