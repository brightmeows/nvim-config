-- 核对盘上已装插件的 git HEAD 与仓库内 lazy-lock.json 的 commit 是否一致，
-- 并校验 spec 图与锁的双向覆盖（锁里有、spec 图里没有；spec 图里有、锁里没有）。
-- 用法：nvim -l scripts/verify-lockfile.lua（在仓库根目录执行）
-- 本地与 CI lockfile job 共用同一脚本，命令串同源。
-- 注意：不拿锁文件字段自比（永真比较）——一律读盘上 git HEAD 与锁比对。
local lock = vim.json.decode(table.concat(vim.fn.readfile("lazy-lock.json"), "\n"))
local root = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")

local bad = {}

-- spec 侧枚举：递归 dependencies；lazy.nvim 是管理器本身，不在 spec 图里。
local config = vim.fn.stdpath("config")
vim.opt.rtp:prepend(config)
local spec_names = {}

local function plugin_name(ref)
  return ref:gsub("%.git$", ""):match("([^/]+)$")
end

local function walk(spec)
  if type(spec) == "string" then
    if spec:match("/") then
      spec_names[plugin_name(spec)] = true
    end
    return
  end
  if type(spec) ~= "table" then
    return
  end
  if type(spec[1]) == "string" and spec[1]:match("/") then
    spec_names[spec.name or plugin_name(spec[1])] = true
  else
    for _, item in ipairs(spec) do
      walk(item)
    end
  end
  if spec.dependencies then
    walk(spec.dependencies)
  end
end

for file, kind in vim.fs.dir(vim.fs.joinpath(config, "lua", "plugins")) do
  if kind == "file" and file:match("%.lua$") then
    local mod = "plugins." .. file:gsub("%.lua$", "")
    local ok, spec = pcall(require, mod)
    if not ok then
      bad[#bad + 1] = ("%s: 加载失败"):format(mod)
    else
      walk(spec)
    end
  end
end

local spec_count = 0
for _ in pairs(spec_names) do
  spec_count = spec_count + 1
end

for name, info in pairs(lock) do
  if info.commit then
    local dir = vim.fs.joinpath(root, name)
    local out = vim.system({ "git", "-C", dir, "rev-parse", "HEAD" }, { text = true }):wait()
    if out.code ~= 0 then
      bad[#bad + 1] = name .. ": not installed"
    else
      local head = vim.trim(out.stdout)
      if head ~= info.commit then
        bad[#bad + 1] = ("%s: installed %s, lock %s"):format(name, head, info.commit)
      end
    end
  end
end

local MANAGER = "lazy.nvim"
for name in pairs(lock) do
  if name ~= MANAGER and not spec_names[name] then
    bad[#bad + 1] = name .. ": 在锁中但不在 spec 图"
  end
end
for name in pairs(spec_names) do
  if not lock[name] then
    bad[#bad + 1] = name .. ": 在 spec 图但不在锁中"
  end
end

table.sort(bad)

if #bad > 0 then
  -- selene: allow(incorrect_standard_library_use) -- lua51 std 的 io.stderr 类型缺 write，无法经 vim.yml 覆盖
  io.stderr:write("LOCKFILE-MISMATCH\n" .. table.concat(bad, "\n") .. "\n")
  vim.cmd("cquit 1")
end
print(
  ("LOCKFILE-OK %d plugins match；spec 图 %d 件（%s 管理器豁免）"):format(
    vim.tbl_count(lock),
    spec_count,
    MANAGER
  )
)
