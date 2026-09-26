---@class meow.util
--- 本配置的工具层。行为源：LazyVim 16.0 lua/lazyvim/util/init.lua，
--- 但剥离全部 lazy.nvim 依赖（has/on_load/opts 等与 lazy spec 耦合的成员
--- 在各调用点按 vim.pack 语义改写，不再集中提供）。
local M = {}

-- 图标与 kind 过滤（meow/icons.lua）
M.icons = require("meow.icons").icons
M.kind_filter = require("meow.icons").kind_filter

-- 兼容移植代码中的 LazyVim.config.icons / config.kind_filter 写法
M.config = { icons = M.icons, kind_filter = M.kind_filter }

-- 子模块懒加载（root/format/pick/lsp/treesitter/mini/lualine/cmp）：
-- 与 LazyVim util 的 __index 行为一致，移植代码的 LazyVim.format.* 等调用由此解析。
setmetatable(M, {
  __index = function(t, k)
    local ok, sub = pcall(require, "meow." .. k)
    if ok then
      rawset(t, k, sub)
      return sub
    end
    return nil
  end,
})

function M.is_win()
  return vim.uv.os_uname().sysname:find("Windows") ~= nil
end

---@param path string?
---@return string?
function M.norm(path)
  if not path then
    return nil
  end
  if path:sub(1, 1) == "~" then
    local home = vim.uv.os_homedir()
    if not home then
      return path
    end
    if path == "~" then
      path = home
    elseif path:sub(1, 2) == "~/" then
      path = home .. path:sub(2)
    end
  end
  return vim.fs.normalize(path)
end

---@generic T: fun()
---@param fn T
---@return T
function M.try(fn, opts)
  local ok, err = pcall(fn)
  if not ok then
    M.error((opts and opts.msg or "Error") .. "\n" .. tostring(err), opts)
  end
  return ok
end

-- 与 LazyVim.set_default 同语义：仅当局部值仍为默认（未被插件/用户改动）
-- 时才写入，避免 treesitter/LSP 的 FileType 钩子互相覆盖或覆盖用户设置。
local _defaults = {} ---@type table<string, boolean>

---@return boolean was_set
function M.set_default(option, value)
  local l = vim.api.nvim_get_option_value(option, { scope = "local" })
  local g = vim.api.nvim_get_option_value(option, { scope = "global" })

  _defaults[("%s=%s"):format(option, value)] = true
  local key = ("%s=%s"):format(option, l)

  if l ~= g and not _defaults[key] then
    -- 局部值已被插件改动：若其来源不是 $VIMRUNTIME 则不覆盖
    local info = vim.api.nvim_get_option_info2(option, { scope = "local" })
    ---@type vim.fn.getscriptinfo.ret
    local scriptinfo = vim.tbl_filter(function(e)
      return e.sid == info.last_set_sid
    end, vim.fn.getscriptinfo())
    local source = scriptinfo[1] and scriptinfo[1].name or ""
    local by_rtp = #scriptinfo == 1 and vim.startswith(source, vim.fn.expand("$VIMRUNTIME"))
    if not by_rtp then
      return false
    end
  end

  vim.api.nvim_set_option_value(option, value, { scope = "local" })
  return true
end

--- statuscolumn：交给 snacks.statuscolumn 渲染（与 LazyVim 同实现）。
--- 由 options.lua 的 %!v:lua 表达式调用。
function M.statuscolumn()
  return package.loaded.snacks and require("snacks.statuscolumn").get() or ""
end

--- vim.keymap.set 包装：默认 silent。
--- LazyVim 版本会探测 lazy 的 keys handler 以避免冲突——本配置无 lazy，
--- 直接走 Snacks.keymap（保留 ft/lsp/enabled 扩展字段的支持）。
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param opts? vim.keymap.set.Opts
function M.safe_keymap_set(mode, lhs, rhs, opts)
  opts = opts or {}
  opts.silent = opts.silent ~= false
  Snacks.keymap.set(mode, lhs, rhs, opts)
end

---@param list any[]
---@return any[]
function M.dedup(list)
  local ret = {}
  local seen = {}
  for _, v in ipairs(list) do
    if not seen[v] then
      table.insert(ret, v)
      seen[v] = true
    end
  end
  return ret
end

--- 深合并（LazyVim.merge 同签名）。
function M.merge(...)
  return vim.tbl_deep_extend("force", {}, ...)
end

M.CREATE_UNDO = vim.api.nvim_replace_termcodes("<c-G>u", true, true, true)
function M.create_undo()
  if vim.api.nvim_get_mode().mode == "i" then
    vim.api.nvim_feedkeys(M.CREATE_UNDO, "n", false)
  end
end

-- 覆盖默认通知标题（原 LazyVim 版本 title = "LazyVim"）。
for _, level in ipairs({ "info", "warn", "error" }) do
  M[level] = function(msg, opts)
    opts = opts or {}
    opts.title = opts.title or "nvim"
    if level == "info" then
      opts.level = vim.log.levels.INFO
    elseif level == "warn" then
      opts.level = vim.log.levels.WARN
    else
      opts.level = vim.log.levels.ERROR
    end
    -- 多行消息拼接为字符串；数组消息逐行合并
    if type(msg) == "table" then
      msg = table.concat(msg, "\n")
    end
    vim.notify(msg, opts.level, opts)
  end
end

return M
