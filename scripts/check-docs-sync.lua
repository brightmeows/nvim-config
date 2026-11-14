-- 文档与配置的命令串同源校验：权威源为 .pre-commit-config.yaml（lint 命令）与
-- .github/workflows/ci.yml（行为脚本），README 与 AGENTS 必须包含同一串。
-- 用法：nvim -l scripts/check-docs-sync.lua
-- 比对前折叠全部空白，避免 YAML 折行与 Markdown 对齐空格造成假差异。
local script = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(script))

local function read(rel)
  local path = vim.fs.joinpath(root, rel)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  return table.concat(lines, "\n"):gsub("%s+", " ")
end

local files = {
  readme = read("README.md"),
  agents = read("AGENTS.md"),
  hooks = read(".pre-commit-config.yaml"),
  ci = read(".github/workflows/ci.yml"),
}

local checks = {
  { source = "hooks", target = "agents", needle = "stylua --check ." },
  { source = "hooks", target = "agents", needle = "selene lua init.lua plugin scripts" },
  { source = "ci", target = "agents", needle = "scripts/verify-lockfile.lua" },
  { source = "ci", target = "agents", needle = "scripts/strong-smoke.lua" },
  { source = "ci", target = "readme", needle = "pre-commit run --all-files" },
}

local bad = {}
for _, check in ipairs(checks) do
  local source = files[check.source]
  local target = files[check.target]
  local needle = check.needle:gsub("%s+", " ")
  if not source then
    bad[#bad + 1] = ("%s 不可读"):format(check.source)
  elseif not target then
    bad[#bad + 1] = ("%s 不可读"):format(check.target)
  elseif not source:find(needle, 1, true) then
    bad[#bad + 1] = ("%s 缺少权威串：%s"):format(check.source, needle)
  elseif not target:find(needle, 1, true) then
    bad[#bad + 1] = ("%s 缺少 %s 里的命令串：%s"):format(check.target, check.source, needle)
  end
end

if #bad > 0 then
  print("DOCS-SYNC-FAIL")
  for _, line in ipairs(bad) do
    print("  " .. line)
  end
  vim.cmd("cquit 1")
end
print(("DOCS-SYNC-OK %d 组命令串一致"):format(#checks))
