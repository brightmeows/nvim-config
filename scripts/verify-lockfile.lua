-- 核对盘上已装插件的 git HEAD 与仓库内 nvim-pack-lock.json 的 rev 是否一致。
-- 用法：nvim -l scripts/verify-lockfile.lua（在仓库根目录执行）
-- 本地与 CI lockfile job 共用同一脚本，命令串同源。
-- 注意：不使用 vim.pack.get().rev——该字段源自锁文件本身，拿它比锁文件是永真比较。
local lock = vim.json.decode(table.concat(vim.fn.readfile("nvim-pack-lock.json"), "\n"))
local opt = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")

local bad = {}
for name, info in pairs(lock.plugins) do
  if info.rev then
    local dir = vim.fs.joinpath(opt, name)
    local out = vim.system({ "git", "-C", dir, "rev-parse", "HEAD" }, { text = true }):wait()
    if out.code ~= 0 then
      bad[#bad + 1] = name .. ": not installed"
    else
      local head = vim.trim(out.stdout)
      if head ~= info.rev then
        bad[#bad + 1] = ("%s: installed %s, lock %s"):format(name, head, info.rev)
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
print("LOCKFILE-OK " .. vim.tbl_count(lock.plugins) .. " plugins match")
