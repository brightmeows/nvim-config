-- 工作树：解析 git worktree list --porcelain，并用 Snacks picker 切换 cwd。
-- 只读列表；创建与删除交给 lazygit。切换后优先打开同名文件，找不到再开目标
-- 目录的文件选择器，让 meow.root 与 LSP 跟着新 buffer 走。
local M = {}

---@class meow.worktree.Entry
---@field path string
---@field head? string
---@field branch? string
---@field bare? boolean
---@field detached? boolean
---@field locked? string|boolean
---@field prunable? string|boolean

local function notify(msg, level)
  vim.notify("meow.worktree: " .. msg, level or vim.log.levels.INFO)
end

---@param entries meow.worktree.Entry[]
---@param entry? meow.worktree.Entry
local function flush(entries, entry)
  if entry and entry.path then
    entries[#entries + 1] = entry
  end
end

---解析 `git worktree list --porcelain` 输出。
---@param output string
---@return meow.worktree.Entry[]
function M.parse(output)
  local entries = {} ---@type meow.worktree.Entry[]
  local current = nil ---@type meow.worktree.Entry?

  for _, raw in ipairs(vim.split(output or "", "\n", { plain = true })) do
    local line = raw:gsub("\r$", "")
    if line == "" then
      flush(entries, current)
      current = nil
    else
      local key, value = line:match("^(%S+)%s*(.*)$")
      if key == "worktree" then
        flush(entries, current)
        current = { path = value }
      elseif current then
        if key == "HEAD" then
          current.head = value
        elseif key == "branch" then
          current.branch = value:gsub("^refs/heads/", "")
        elseif key == "detached" then
          current.detached = true
        elseif key == "bare" then
          current.bare = true
        elseif key == "locked" then
          current.locked = value ~= "" and value or true
        elseif key == "prunable" then
          current.prunable = value ~= "" and value or true
        end
      end
    end
  end
  flush(entries, current)
  return entries
end

---@param cwd? string
---@return meow.worktree.Entry[]|nil, string|nil
function M.list(cwd)
  cwd = cwd or require("meow.root").git()
  local out = vim.system({ "git", "-C", cwd, "worktree", "list", "--porcelain" }, { text = true }):wait()
  if out.code ~= 0 then
    return nil, vim.trim(out.stderr ~= "" and out.stderr or out.stdout or "")
  end
  return M.parse(out.stdout or "")
end

---@param path string
function M.switch(path)
  local old = vim.fn.getcwd()
  local target = vim.fs.normalize(path)
  if vim.fs.normalize(old) == target then
    notify("already in " .. target)
    return
  end

  local top = vim.system({ "git", "-C", old, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  local root = top.code == 0 and vim.trim(top.stdout or "") or nil
  local name = vim.api.nvim_buf_get_name(0)
  local rel = nil
  if root and name ~= "" then
    local root_norm = vim.fs.normalize(root)
    local name_norm = vim.fs.normalize(name)
    if name_norm:sub(1, #root_norm + 1) == root_norm .. "/" then
      rel = name_norm:sub(#root_norm + 2)
    end
  end

  local ok, err = pcall(vim.fn.chdir, target)
  if not ok then
    notify(tostring(err), vim.log.levels.ERROR)
    return
  end
  vim.cmd("redrawstatus!")

  if rel then
    local candidate = vim.fs.joinpath(target, rel)
    if vim.fn.filereadable(candidate) == 1 then
      local edit_ok, edit_err = pcall(vim.cmd.edit, vim.fn.fnameescape(candidate))
      if not edit_ok then
        notify(tostring(edit_err), vim.log.levels.ERROR)
      end
      notify("switched to " .. target)
      return
    end
  end

  notify("switched to " .. target)
  Snacks.picker.files({ cwd = target })
end

function M.picker()
  if not Snacks or not Snacks.picker then
    notify("snacks picker not loaded", vim.log.levels.ERROR)
    return
  end

  local entries, err = M.list()
  if not entries then
    notify(err ~= "" and err or "git worktree list failed", vim.log.levels.ERROR)
    return
  end

  local current = vim.fs.normalize(vim.fn.getcwd())
  local items = {}
  for _, entry in ipairs(entries) do
    if not entry.bare and not entry.prunable then
      local path = vim.fs.normalize(entry.path)
      local branch = entry.branch or (entry.detached and ("detached " .. (entry.head or ""):sub(1, 7))) or "(unknown)"
      local is_current = path == current or current:sub(1, #path + 1) == path .. "/"
      items[#items + 1] = {
        text = branch .. " " .. path,
        path = entry.path,
        branch = branch,
        head = entry.head,
        locked = entry.locked,
        current = is_current,
      }
    end
  end

  if #items == 0 then
    notify("no switchable worktrees", vim.log.levels.WARN)
    return
  end

  table.sort(items, function(a, b)
    if a.current ~= b.current then
      return a.current
    end
    return a.path < b.path
  end)

  Snacks.picker.pick({
    title = "Worktrees",
    items = items,
    layout = { preview = false },
    format = function(item)
      local ret = {} ---@type snacks.picker.Highlight[]
      if item.current then
        ret[#ret + 1] = { "* ", "SnacksPickerGitBranchCurrent" }
      else
        ret[#ret + 1] = { "  " }
      end
      ret[#ret + 1] = { item.branch, "SnacksPickerGitBranch" }
      ret[#ret + 1] = { "  " .. vim.fs.normalize(item.path), "SnacksPickerDir" }
      if item.head then
        ret[#ret + 1] = { "  " .. item.head:sub(1, 7), "SnacksPickerComment" }
      end
      if item.locked then
        ret[#ret + 1] = { "  locked", "SnacksPickerComment" }
      end
      return ret
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(function()
          M.switch(item.path)
        end)
      end
    end,
  })
end

function M.setup()
  vim.api.nvim_create_user_command("WorktreeSwitch", function()
    M.picker()
  end, { desc = "Switch Git Worktree", force = true })
end

return M
