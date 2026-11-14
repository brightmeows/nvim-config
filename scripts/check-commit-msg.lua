-- Conventional Commits 骨架校验，commit-msg 阶段调用。
-- 用法：nvim -l scripts/check-commit-msg.lua <commit-msg 文件>
-- 规则：首个非注释行匹配 type(scope)!: 主题；type 取白名单；scope 可选且 kebab-case；
-- Merge、Revert、fixup、squash、amend 豁免；不校验主题语言与 scope 取值。
local TYPES = {
  build = true,
  chore = true,
  ci = true,
  docs = true,
  feat = true,
  fix = true,
  perf = true,
  refactor = true,
  revert = true,
  style = true,
  test = true,
}

local EXEMPT = { "^Merge ", '^Revert "', "^fixup!", "^squash!", "^amend!" }

local function reject(lines)
  print("COMMIT-MSG-FAIL 提交信息不符合规范")
  for _, line in ipairs(lines) do
    print("  " .. line)
  end
  print("  期望：type(scope)!: 主题，例：fix(ci): 修正锁对齐")
  print("  type 白名单：" .. table.concat(vim.tbl_keys(TYPES), "、"))
  vim.cmd("cquit 1")
end

local function main()
  local path = (arg or {})[1]
  if not path then
    reject({ "缺少 commit-msg 文件路径" })
  end

  local read_ok, lines = pcall(vim.fn.readfile, path)
  if not read_ok then
    reject({ "无法读取 " .. path })
  end

  local subject
  for _, line in ipairs(lines) do
    if not (line:match("^%s*#") or line:match("^%s*$")) then
      subject = vim.trim(line)
      break
    end
  end
  if not subject or subject == "" then
    reject({ "首个非注释行为空" })
  end

  for _, pattern in ipairs(EXEMPT) do
    if subject:find(pattern) then
      print("COMMIT-MSG-OK 豁免：" .. subject)
      return
    end
  end

  local problems = {}
  local kind, rest = subject:match("^(%a+)(.*)$")
  local scope, bang
  if not kind then
    problems[#problems + 1] = "不符合 type(scope)!: 主题 形状"
  else
    if not TYPES[kind] then
      problems[#problems + 1] = "未知 type：" .. kind
    end

    if rest:sub(1, 1) == "(" then
      local inner, tail = rest:match("^%(([^)]*)%)(.*)$")
      if not inner then
        problems[#problems + 1] = "scope 括号未闭合"
      elseif not inner:match("^[%l][%l%d%-]*$") then
        problems[#problems + 1] = "scope 须为小写 kebab-case：" .. inner
      else
        scope = inner
      end
      rest = tail or ""
    end

    if rest:sub(1, 1) == "!" then
      bang = true
      rest = rest:sub(2)
    end

    if rest:sub(1, 1) ~= ":" then
      problems[#problems + 1] = "缺少冒号"
    elseif vim.trim(rest:sub(2)) == "" then
      problems[#problems + 1] = "主题为空"
    end
  end

  if #problems > 0 then
    problems[#problems + 1] = "subject：" .. subject
    reject(problems)
  end
  print(("COMMIT-MSG-OK type=%s scope=%s bang=%s"):format(kind, scope or "-", bang and "yes" or "no"))
end

main()
