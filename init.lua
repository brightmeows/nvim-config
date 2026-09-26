-- 入口：vim.pack 装载 lua/plugins/ 下的插件（无 lazy.nvim / LazyVim）。
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")

-- 插件 spec 收集：每文件返回一个 vim.pack spec（{ src = "..." }）或其列表，
-- 可附带 config 字段（函数）。先全部 add（rtp 就位），再按文件名字典序执行
-- config——加载序由此确定，不依赖文件系统遍历顺序。
local function is_spec(t)
  return type(t) == "table" and type(t.src) == "string"
end

local files = {}
local plugin_dir = vim.fn.stdpath("config") .. "/lua/plugins"
if vim.fn.isdirectory(plugin_dir) == 1 then
  for name, kind in vim.fs.dir(plugin_dir) do
    if (kind == "file" or kind == "link") and name:match("%.lua$") then
      files[#files + 1] = name:gsub("%.lua$", "")
    end
  end
end
table.sort(files)

local specs, configs = {}, {}
for _, mod in ipairs(files) do
  local ret = require("plugins." .. mod)
  local list = is_spec(ret) and { ret } or ret
  if type(list) ~= "table" then
    error(("lua/plugins/%s.lua 返回值必须是 spec 或 spec 列表"):format(mod))
  end
  for i, spec in ipairs(list) do
    if not is_spec(spec) then
      error(("lua/plugins/%s.lua 第 %d 项不是合法 spec（缺 src 字符串）"):format(mod, i))
    end
    if spec.config ~= nil and type(spec.config) ~= "function" then
      error(("lua/plugins/%s.lua 的 config 必须是函数"):format(mod))
    end
    configs[#configs + 1] = { mod = mod, config = spec.config }
    spec.config = nil -- 移出 spec，避免干扰 vim.pack 的字段处理
    specs[#specs + 1] = spec
  end
end

if #specs > 0 then
  -- confirm = false：非交互环境（headless / CI）不阻塞在安装确认上，
  -- 首次启动即按锁文件或 spec 版本装齐。
  vim.pack.add(specs, { confirm = false })
end

-- Snacks 全局在 require("snacks") 时建立；config 按文件名字典序执行，
-- gitsigns/which-key 等字母序在 snacks 之前的文件也依赖它，先建立。
pcall(require, "snacks")

for _, c in ipairs(configs) do
  if c.config then
    -- 错误直接上抛：启动失败必须可见，headless smoke 才能捕获
    c.config()
  end
end

require("config.autocmds")
require("config.keymaps")

-- LazyVim 在 VeryLazy 阶段调用的 setup（行为源：config/init.lua:197-199）：
-- format.setup 注册 BufWritePre 自动格式化与 :LazyFormat 命令；
-- root.setup 注册根目录缓存失效 autocmd。
require("meow.format").setup()
require("meow.root").setup()

-- Omarchy 主题耦合（行为源：原 lua/plugins/theme.lua symlink +
-- omarchy-theme-hotreload.lua）：启动时应用当前主题（上游 spec 存在时
-- 覆盖 colorscheme.lua 的静态回退），随后 watch 父目录实现热重载。
require("meow.theme").load()
require("meow.theme").watch()
