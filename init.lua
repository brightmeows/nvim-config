-- 入口：lazy.nvim 装载 lua/plugins/ 下的插件 spec。
-- 行为源：LazyVim 16.0 的加载时序（lazyvim/config/init.lua M.setup 的 User
-- VeryLazy 回调、lazyvim/util/plugin.lua 的 LazyFile glue）；bootstrap 与
-- lazy.setup 选项对齐基线 config/lazy.lua（e6b27cf）。
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")

-- bootstrap：克隆 stable tag（当前指向 v11.17.5）；多机版本一致由
-- lazy-lock.json 收敛，bootstrap 只决定首克隆落点。
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit...", "ErrorMsg" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
  -- 首克隆对齐（2026-10-17 CI lockfile job 失败根因）：bootstrap 落点是 stable 分支
  -- HEAD，而 lazy-lock.json 锁的 lazy.nvim 可能已随同步升到 main 分支 commit，首克隆
  -- HEAD 与锁分叉会让 verify-lockfile 必挂。只在本次确实克隆时 checkout：每次启动都跑
  -- 要多付约 200ms，后续错位由 meow.lockguard 异步只读提示 :Lazy restore。
  local lock_path = vim.fs.joinpath(vim.fn.stdpath("config"), "lazy-lock.json")
  if vim.uv.fs_stat(lock_path) then
    local ok, lock = pcall(vim.json.decode, table.concat(vim.fn.readfile(lock_path), "\n"))
    local commit = ok and type(lock) and lock["lazy.nvim"] and lock["lazy.nvim"].commit
    if commit then
      vim.fn.system({ "git", "-C", lazypath, "checkout", "--detach", commit, "-q" })
    end
  end
end
vim.opt.rtp:prepend(lazypath)

-- LazyFile 事件 glue（行为源：lazyvim/util/plugin.lua M.lazy_file，
-- 事件组 BufReadPost/BufNewFile/BufWritePre 与 LazyVim 16.0 一致）
local lazy_event = require("lazy.core.handler.event")
lazy_event.mappings.LazyFile = {
  id = "LazyFile",
  event = { "BufReadPost", "BufNewFile", "BufWritePre" },
}
lazy_event.mappings["User LazyFile"] = lazy_event.mappings.LazyFile

-- Omarchy 主题 spec 注入：校验预装集，缺件剔除并显式报错（与热重载同口径）
local theme = require("meow.theme")

require("lazy").setup({
  spec = {
    theme.spec(),
    { import = "plugins" },
  },
  defaults = {
    -- LazyVim 同款：默认不懒，懒加载由各 spec 的事件字段声明
    lazy = false,
    -- 版本权威在 lazy-lock.json；钉法特例写在 spec 内（blink tag、aether branch）
    version = false,
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- 每小时检查更新（lazy 默认频率，基线同款）
    notify = false, -- 更新数仅经 lualine 呈现，不发通知
  },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})

-- 当前主题应用与热重载 watcher（注入已在 setup 前完成，此处只管应用；
-- 非 Omarchy 机器走静态回退）
theme.load()
theme.watch()

-- 多机版本对齐守卫：只读比对锁与盘上 HEAD，不一致时提示 :Lazy restore
require("meow.lockguard").start()

-- 行为源：LazyVim 16.0 lazyvim/config/init.lua M.setup 的 User VeryLazy 回调——
-- autocmds 按 argc 决定早加载或 VeryLazy；keymaps 与 format/root setup 在 VeryLazy。
local lazy_autocmds = vim.fn.argc(-1) == 0
if not lazy_autocmds then
  require("config.autocmds")
end
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    if lazy_autocmds then
      require("config.autocmds")
    end
    require("config.keymaps")
    require("meow.format").setup()
    require("meow.root").setup()
  end,
})
