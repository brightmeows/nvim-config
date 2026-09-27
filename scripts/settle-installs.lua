-- CI 安装步专用：等插件目录按锁就位，再等 mason 的 ensure 安装收敛。
-- 不设判据的安装步内执行（无 Error grep），目的是让后续强测步零在途安装：
--   1) 按 lazy-lock.json 条目数等待 lazy 根目录就位（bootstrap 与缺件安装在
--      首启内同步完成，此循环兑底异步变体）；
--   2) require("mason-registry") 触发 mason 加载（其 config 内 ensure
--      stylua/shfmt），refresh 就绪后轮询 is_installing 直至全部收敛。
-- 本地跑等价于秒过（件齐、包已装）。
local lock = vim.json.decode(table.concat(vim.fn.readfile("lazy-lock.json"), "\n"))
local total = vim.tbl_count(lock)
local root = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")

local function count()
  local c = 0
  for _ in vim.fs.dir(root) do
    c = c + 1
  end
  return c
end

vim.wait(300000, function()
  return count() >= total
end, 500)
if count() < total then
  -- selene: allow(incorrect_standard_library_use) -- lua51 std 的 io.stderr 类型缺 write，无法经 vim.yml 覆盖
  io.stderr:write(("INSTALL-INCOMPLETE %d/%d\n"):format(count(), total))
  vim.cmd("cquit 1")
end

-- mason 收敛：注册表就绪后等待无安装在途
local ok, mr = pcall(require, "mason-registry")
if ok then
  local refreshed = false
  mr.refresh(function()
    refreshed = true
  end)
  vim.wait(120000, function()
    return refreshed
  end, 100)
  vim.wait(300000, function()
    for _, pkg in ipairs(mr.get_all_packages()) do
      if pkg:is_installing() then
        return false
      end
    end
    return true
  end, 500)
end

print(("SETTLE-OK %d/%d plugins, mason idle"):format(count(), total))
