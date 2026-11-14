-- 启动耗时闸门：子进程跑 N 次 --startuptime，取中位与仓库内基线比对。
-- 用法：nvim -l scripts/startup-gate.lua [--update]
-- 判据：中位超出 基线 x factor + floor_ms 即失败（factor 与 floor 存于基线文件）。
-- 基线随机器与 Neovim 版本变化，换机或大版本升级后跑 --update 重定。
local script = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(script))
local baseline_path = vim.fs.joinpath(root, "scripts", "startup-baseline.json")
local runs = 5

local function measure()
  local out = vim.fn.tempname()
  local proc = vim
    .system({
      "nvim",
      "--headless",
      "--startuptime",
      out,
      "+qa",
    }, { text = true, env = { NVIM = false } })
    :wait()
  local ok_read, lines = pcall(vim.fn.readfile, out)
  pcall(vim.fn.delete, out)
  if proc.code ~= 0 or not ok_read then
    return nil, ("启动子进程失败：code=%s"):format(proc.code)
  end
  for _, line in ipairs(lines) do
    local ms = line:match("^([%d%.]+)%s+[%d%.]+:%s+%-%-%- NVIM STARTED %-%-%-")
    if ms then
      return tonumber(ms)
    end
  end
  return nil, "未在 startuptime 输出中找到 NVIM STARTED 行"
end

local samples = {}
for i = 1, runs do
  local ms, err = measure()
  if not ms then
    print("STARTUP-GATE-FAIL " .. err)
    vim.cmd("cquit 1")
  end
  samples[i] = ms
end
table.sort(samples)
local median = samples[math.floor((#samples + 1) / 2)]

local function load_baseline()
  local ok, raw = pcall(vim.fn.readfile, baseline_path)
  if not ok then
    return nil
  end
  local decoded_ok, data = pcall(vim.json.decode, table.concat(raw, "\n"))
  if not decoded_ok or type(data) ~= "table" or type(data.median_ms) ~= "number" then
    return nil
  end
  return data
end

local update = (arg or {})[1] == "--update"
local baseline = load_baseline()

local function show(label, value)
  print(("%s=%s"):format(label, value))
end

if update then
  local data = {
    median_ms = median,
    runs = samples,
    factor = baseline and baseline.factor or 1.5,
    floor_ms = baseline and baseline.floor_ms or 20,
    recorded = os.date("%Y-%m-%d"),
  }
  vim.fn.writefile({ vim.json.encode(data) }, baseline_path)
  show("STARTUP-GATE-UPDATED", table.concat(samples, "/") .. " median=" .. median)
  os.exit(0)
end

if not baseline then
  print("STARTUP-GATE-FAIL 缺少基线，先跑 nvim -l scripts/startup-gate.lua --update")
  vim.cmd("cquit 1")
end

local limit = baseline.median_ms * (baseline.factor or 1.5) + (baseline.floor_ms or 20)
show("STARTUP-GATE-RUNS", table.concat(samples, "/"))
show("STARTUP-GATE-MEDIAN", ("%.1fms"):format(median))
show(
  "STARTUP-GATE-LIMIT",
  ("%.1fms（基线 %.1fms，记录于 %s）"):format(limit, baseline.median_ms, baseline.recorded or "?")
)
if median > limit then
  print("STARTUP-GATE-FAIL 启动耗时超出容差")
  vim.cmd("cquit 1")
end
print("STARTUP-GATE-OK")
