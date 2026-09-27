-- 核对盘上已装插件的 git HEAD 与仓库内 lazy-lock.json 的 commit 是否一致。
-- 用法：nvim -l scripts/verify-lockfile.lua（在仓库根目录执行）
-- 本地与 CI lockfile job 共用同一脚本，命令串同源。
-- 注意：不拿锁文件字段自比（永真比较）——一律读盘上 git HEAD 与锁比对。
local lock = vim.json.decode(table.concat(vim.fn.readfile("lazy-lock.json"), "\n"))
local root = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")

local bad = {}
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
table.sort(bad)

if #bad > 0 then
  -- selene: allow(incorrect_standard_library_use) -- lua51 std 的 io.stderr 类型缺 write，无法经 vim.yml 覆盖
  io.stderr:write("LOCKFILE-MISMATCH\n" .. table.concat(bad, "\n") .. "\n")
  vim.cmd("cquit 1")
end
print("LOCKFILE-OK " .. vim.tbl_count(lock) .. " plugins match")
