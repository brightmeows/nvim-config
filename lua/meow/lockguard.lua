-- 多机版本对齐守卫：启动后延迟只读比对 lazy-lock.json 与盘上各插件 HEAD，
-- 不一致时提示执行 `:Lazy restore` 对齐（锁即真值的既有承诺由此保住——
-- lazy 启动只补缺失件，不回修已装错位件）。
--
-- 设计约束：只读（git rev-parse，不 fetch 不 checkout）、后台异步（并发池，
-- 不拖启动）、pcall 隔离（守卫自身故障不得影响启动）、每次启动只查一轮
--（错位只在拉取后出现，重启即覆盖该场景），CI 短命进程不触发。
local M = {}

M.STARTUP_DELAY = 30 -- 秒，启动后延迟首查
M.CONCURRENCY = 5
M.TIMEOUT = 15000 -- ms，单仓库 rev-parse 超时

--- 后台启动一轮比对；发现问题 notify 一次（WARN）。
function M.start()
  vim.defer_fn(function()
    local ok, err = pcall(M.check)
    if not ok then
      vim.notify("对齐守卫执行失败（不影响使用）:\n" .. tostring(err), vim.log.levels.WARN, {
        title = "lazy-lock",
      })
    end
  end, M.STARTUP_DELAY * 1000)
end

--- 单轮检查：lock 有 commit 而盘上 HEAD 不等者记入 mismatches。
function M.check()
  local lock_path = vim.fn.stdpath("config") .. "/lazy-lock.json"
  if vim.fn.filereadable(lock_path) ~= 1 then
    return
  end
  local ok, lock = pcall(vim.json.decode, table.concat(vim.fn.readfile(lock_path), "\n"))
  if not ok or type(lock) ~= "table" then
    return
  end
  local root = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy")

  local names = {}
  for name, info in pairs(lock) do
    if type(info) == "table" and info.commit then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  if #names == 0 then
    return
  end

  local mismatches = {}
  local pending, idx = 0, 1

  local function finish()
    if pending > 0 or idx <= #names then
      return
    end
    if #mismatches == 0 then
      return
    end
    table.sort(mismatches)
    -- vim.system 回调处于 fast context，notify 必须回主线程
    vim.schedule(function()
      vim.notify(
        ("锁文件与已装插件版本不一致（%d 件）:\n%s\n执行 :Lazy restore 对齐"):format(
          #mismatches,
          table.concat(mismatches, "\n")
        ),
        vim.log.levels.WARN,
        { title = "lazy-lock" }
      )
    end)
  end

  local function pump()
    while pending < M.CONCURRENCY and idx <= #names do
      local name = names[idx]
      idx = idx + 1
      pending = pending + 1
      local dir = vim.fs.joinpath(root, name)
      vim.system({ "git", "-C", dir, "rev-parse", "HEAD" }, { timeout = M.TIMEOUT, text = true }, function(out)
        local head = out and out.code == 0 and vim.trim(out.stdout or "") or nil
        -- 目录缺失属“缺失件”，lazy 启动自会按锁补装，不算错位
        if head and head ~= lock[name].commit then
          mismatches[#mismatches + 1] = ("%s: 盘上 %s，锁 %s"):format(
            name,
            head:sub(1, 9),
            lock[name].commit:sub(1, 9)
          )
        end
        pending = pending - 1
        pump()
        finish()
      end)
    end
    finish()
  end

  pump()
end

return M
