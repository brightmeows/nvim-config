-- meow 纯函数单元测试：nvim -l scripts/test-meow.lua
-- 不加载 init.lua（-l 的默认行为），只把仓库根加入 rtp 后直接 require 被测模块。
-- 覆盖面：snippet 三个纯函数、图标表结构、主题 spec 的不变量、对齐守卫常量。
local script = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(script))
vim.opt.rtp:prepend(root)

local passed, failed = 0, {}

local function eq(actual, expected, name)
  if vim.deep_equal(actual, expected) then
    passed = passed + 1
  else
    failed[#failed + 1] = ("%s：期望 %s，实得 %s"):format(name, vim.inspect(expected), vim.inspect(actual))
  end
end

local function ok(cond, name, detail)
  if cond then
    passed = passed + 1
  else
    failed[#failed + 1] = name .. (detail and ("：" .. detail) or "")
  end
end

local cmp = require("meow.cmp")

eq(
  cmp.snippet_replace("${1:foo} ${2:bar}", function(p)
    return ("<%d:%s>"):format(p.n, p.text)
  end),
  "<1:foo> <2:bar>",
  "snippet_replace 替换两个占位符"
)
eq(
  cmp.snippet_replace("no placeholders", function()
    return "x"
  end),
  "no placeholders",
  "snippet_replace 无占位符时原样返回"
)
eq(cmp.snippet_preview("${1:foo}"), "foo", "snippet_preview 单占位符")
eq(
  cmp.snippet_preview("for ${1:i} in ${2:list} do\n\t$0\nend"),
  "for i in list do\n\t\nend",
  "snippet_preview 多占位符与 $0"
)
eq(cmp.snippet_fix("${1:${2:inner}}"), "${1:inner}", "snippet_fix 嵌套占位符")
eq(cmp.snippet_fix("${1:foo}"), "${1:foo}", "snippet_fix 普通占位符保持")

local icons = require("meow.icons").icons
local kinds_n = 0
for _, value in pairs(icons.kinds or {}) do
  kinds_n = kinds_n + 1
  ok(
    type(value) == "string" or (type(value) == "table" and type(value[1]) == "string"),
    "图标 kinds 条目形态",
    vim.inspect(value)
  )
end
ok(kinds_n >= 20, "图标 kinds 数量", tostring(kinds_n))
ok(next(icons.ft or {}) ~= nil, "图标 ft 表非空")
ok(next(icons.dap or {}) ~= nil, "图标 dap 表非空")

-- 主题 spec 依赖机器状态：有 Omarchy 主题文件时返回注入条目，无则返回空表。
-- 两种情况的共同不变量是类型与字段形态。
local theme_spec = require("meow.theme").spec()
ok(type(theme_spec) == "table", "theme.spec 返回表")
for _, entry in ipairs(theme_spec) do
  ok(type(entry[1]) == "string", "主题条目 url", vim.inspect(entry))
  ok(type(entry.name) == "string", "主题条目 name", vim.inspect(entry))
end

local lockguard = require("meow.lockguard")
ok(type(lockguard.STARTUP_DELAY) == "number" and lockguard.STARTUP_DELAY > 0, "lockguard 延迟为正数")
ok(type(lockguard.CONCURRENCY) == "number" and lockguard.CONCURRENCY > 0, "lockguard 并发为正数")
ok(type(lockguard.TIMEOUT) == "number" and lockguard.TIMEOUT > 0, "lockguard 超时为正数")

local worktree = require("meow.worktree")
local porcelain = table.concat({
  "worktree /repo/main",
  "HEAD 1111111111111111111111111111111111111111",
  "branch refs/heads/main",
  "",
  "worktree /repo/feature",
  "HEAD 2222222222222222222222222222222222222222",
  "branch refs/heads/feature/x",
  "locked in use",
  "",
  "worktree /repo/detached",
  "HEAD 3333333333333333333333333333333333333333",
  "detached",
  "",
  "worktree /repo/gone",
  "HEAD 4444444444444444444444444444444444444444",
  "branch refs/heads/gone",
  "prunable gitdir file points to non-existent location",
  "",
  "worktree /repo/bare.git",
  "HEAD 5555555555555555555555555555555555555555",
  "bare",
  "",
}, "\n")

local trees = worktree.parse(porcelain)
eq(#trees, 5, "worktree.parse 条目数")
eq(trees[1].path, "/repo/main", "worktree.parse 主树路径")
eq(trees[1].branch, "main", "worktree.parse 去 refs/heads 前缀")
eq(trees[1].detached, nil, "worktree.parse 主树非 detached")
eq(trees[2].branch, "feature/x", "worktree.parse 分支带斜杠")
eq(trees[2].locked, "in use", "worktree.parse locked 带原因")
eq(trees[3].detached, true, "worktree.parse detached")
eq(trees[4].prunable, "gitdir file points to non-existent location", "worktree.parse prunable 带原因")
eq(trees[5].bare, true, "worktree.parse bare")
eq(worktree.parse(""), {}, "worktree.parse 空输出")
eq(
  worktree.parse("worktree /a\r\nHEAD x\r\nbranch refs/heads/a\r\n"),
  { { path = "/a", head = "x", branch = "a" } },
  "worktree.parse CRLF 与无尾空行"
)
eq(worktree.parse("worktree /b\nHEAD y\nlocked\n\n")[1].locked, true, "worktree.parse locked 无原因")

if #failed > 0 then
  print("MEOW-TESTS-FAIL " .. #failed)
  for _, msg in ipairs(failed) do
    print("  " .. msg)
  end
  vim.cmd("cquit 1")
end
print(("MEOW-TESTS-OK %d 项"):format(passed))
