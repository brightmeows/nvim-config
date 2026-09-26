-- 插件更新后台检查器。
--
-- 行为基线：lazy.nvim 的 checker（frequency=3600s 每小时、notify=false——
-- 更新数仅经 lualine 计数呈现，不发通知），迁移时该闭环缺失，此处补齐。
-- vim.pack 无“仅检查”API（update 必开确认页或直接应用），故自写：
--   git ls-remote 查询 spec.version 声明的 ref 远端 tip，与盘上 rev 比对。
-- ls-remote 只读远端、不动本地（无锁冲突、无 fetch 副作用）。
-- 钉死形态（纯 hex commit / vim.VersionRange）无远端可比，视作无更新。
local M = {}

local uv = vim.uv or vim.loop

M.FREQUENCY = 3600 -- 秒，对齐 lazy checker 默认 frequency
M.STARTUP_DELAY = 30 -- 秒，启动后延迟首查（不拖累启动、CI 短命进程不触发）
M.CONCURRENCY = 5
M.TIMEOUT = 15000 -- ms，单仓库 ls-remote 超时（离线容错）

---@type table<string, boolean> 插件名 → 远端有无新提交
M._updates = {}
M._running = false

--- 更新计数（lualine 组件与 cond 共用）。
function M.count()
  local n = 0
  for _, has in pairs(M._updates) do
    if has then
      n = n + 1
    end
  end
  return n
end

--- 对齐 lazy.status.updates 的返回形态：icon（U+F487 + 空格）+ 计数，
--- 无更新时返回 nil（lualine 组件显示空）。
function M.status()
  local n = M.count()
  return n > 0 and (" " .. n) or nil
end

function M.has_updates()
  return M.count() > 0
end

---@param plug vim.pack.Plug
---@param done fun()
local function check_one(plug, done)
  local version = plug.spec.version
  local cb = vim.schedule_wrap(done)

  -- 钉死为 commit（纯 hex ref）或版本区间：无可比远端 tip，跳过
  if version ~= nil and type(version) ~= "string" then
    cb()
    return
  end
  if type(version) == "string" and #version >= 7 and version:match("^%x+$") then
    cb()
    return
  end

  local args
  if version == nil then
    -- 默认分支 tip
    args = { "git", "-C", plug.path, "ls-remote", "origin", "HEAD" }
  else
    -- 分支或 tag 同名歧义时一次查全；peeled tag（^{}`）优先于 tag 对象本身
    args = {
      "git",
      "-C",
      plug.path,
      "ls-remote",
      "origin",
      "refs/heads/" .. version,
      "refs/tags/" .. version,
      "refs/tags/" .. version .. "^{}",
    }
  end

  vim.system(args, { timeout = M.TIMEOUT }, function(out)
    if out.code ~= 0 then
      -- 离线/网络失败：保留该插件旧状态，不误报
      cb()
      return
    end
    local sha
    if version == nil then
      sha = out.stdout:match("^(%x+)")
    else
      local peeled = out.stdout:match("(%x+)\t" .. vim.pesc("refs/tags/" .. version .. "^{}"))
      sha = peeled or out.stdout:match("^(%x+)")
    end
    if sha then
      M._updates[plug.spec.name] = sha ~= plug.rev
    end
    cb()
  end)
end

--- 单轮检查（并发池；运行中重入直接返回）。
function M.check()
  if M._running then
    return
  end
  local plugs = vim.pack.get()
  if #plugs == 0 then
    return
  end
  M._running = true
  local pending, idx = 0, 1

  local function finish()
    if pending == 0 and idx > #plugs then
      M._running = false
    end
  end

  local function pump()
    while pending < M.CONCURRENCY and idx <= #plugs do
      local plug = plugs[idx]
      idx = idx + 1
      pending = pending + 1
      check_one(plug, function()
        pending = pending - 1
        pump()
        finish()
      end)
    end
  end

  pump()
  finish()
end

--- 启动：延迟首查，此后每 FREQUENCY 周期复查（uv timer 常驻至进程退出）。
function M.start()
  vim.defer_fn(function()
    M.check()
    if not M._timer then
      M._timer = uv.new_timer()
      M._timer:start(
        M.FREQUENCY * 1000,
        M.FREQUENCY * 1000,
        vim.schedule_wrap(function()
          M.check()
        end)
      )
    end
  end, M.STARTUP_DELAY * 1000)
end

return M
