-- 强测 smoke：headless 下把插件加载面拉满，替代“只测启动路径”的弱 smoke。
-- 用法：nvim --headless -c 'luafile scripts/strong-smoke.lua' -c 'qa!'
-- 判据与弱 smoke 同源：退出码 0 且输出无 Error。
--
-- 机制：事件触发加程序化补载双保险——headless 无 UIEnter，lazy 的 VeryLazy
-- 自动路径不会走到，手动触发对齐真实 TUI 语义；随后对仍未加载的插件
-- （cmd/keys-only 触发件、事件未命中的边缘件）程序化走 lazy 内部
-- Loader.load，保证每份 config 都被执行过；最终判据由外层退出码与输出 grep 执行。
local Config = require("lazy.core.config")
local Loader = require("lazy.core.loader")

local function fire(event, opts)
  local ok, err = pcall(vim.api.nvim_exec_autocmds, event, opts or {})
  if not ok then
    print(("SMOKE-FIRE-FAIL %s: %s"):format(event, tostring(err)))
  end
end

-- 对齐真实 VeryLazy 路径的状态位与事件
vim.g.did_very_lazy = true
fire("User", { pattern = "VeryLazy", modeline = false })
fire("User", { pattern = "LazyFile", modeline = false })
fire("BufReadPre", { buffer = 0 })
fire("BufNewFile", { buffer = 0 })
fire("BufReadPost", { buffer = 0 })
fire("BufWritePre", { buffer = 0 })
fire("InsertEnter", { buffer = 0 })
fire("CmdlineEnter")

-- 程序化补载：覆盖 cmd/keys-only 与事件未命中的插件
local missing = {}
for name, plugin in pairs(Config.plugins) do
  if not plugin._.loaded and plugin.cond ~= false then
    missing[#missing + 1] = name
  end
end
table.sort(missing)
if #missing > 0 then
  Loader.load(missing, { smoke = "strong" })
end

-- 终态统计：除 cond=false 外应全部载入
local total, loaded, stuck = 0, 0, {}
for name, plugin in pairs(Config.plugins) do
  if plugin.cond ~= false then
    total = total + 1
    if plugin._.loaded then
      loaded = loaded + 1
    else
      stuck[#stuck + 1] = name
    end
  end
end
table.sort(stuck)
print(("STRONG-SMOKE loaded %d/%d"):format(loaded, total))
if #stuck > 0 then
  print("STRONG-SMOKE-NOT-LOADED " .. table.concat(stuck, ","))
end
print("STRONG-SMOKE-DONE")
