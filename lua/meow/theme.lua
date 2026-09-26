-- Omarchy 主题耦合：兼容解析器 + 热重载 watcher。
--
-- 上游机制（已探明）：`omarchy-theme-set` 从 default/themed/neovim.lua.tpl
-- 生成 lazy.nvim 格式的 spec 到 ~/.local/state/omarchy/current/theme/neovim.lua，
-- 内含主题插件条目（可能带 opts.colors）与一段
-- { "LazyVim/LazyVim", opts = { colorscheme = "..." } }。
-- 目录切换为 rm -rf + mv 原子替换（omarchy-theme-set 源码 292-293 行），
-- 故 watcher 必须 watch 父目录 current/ 而非 theme/ 的 inode。
--
-- 本模块职责：
--   load()   —— dofile 上游 spec，断言结构（缺字段即报错不静默），
--               经 vim.pack.add 保证主题插件在位，setup opts，应用 colorscheme。
--   watch()  —— fs_event watch current/ 父目录，事件 debounce 1500ms
--               （吸收 aether CLI/omarchy 的连续写入），重挂失效句柄，
--               触发 load() 并重放 ColorScheme 后续（透明度重应用等）。
local M = {}

local uv = vim.uv or vim.loop

local OMARCHY_STATE = vim.fn.expand("~/.local/state/omarchy/current")
local SPEC_PATH = OMARCHY_STATE .. "/theme/neovim.lua"
local TRANSPARENCY = vim.fn.stdpath("config") .. "/plugin/after/transparency.lua"

-- watcher 状态（挂 _G 防模块重载时句柄泄漏——aether 同款教训）
local state = _G.__meow_theme_watch or {
  handle = nil,
  timer = nil,
  rearm_timer = nil,
}
_G.__meow_theme_watch = state

--- 从上游 spec 提取主题插件列表与 colorscheme 名。
--- 上游结构：条目 1..n 为插件 spec（字符串或 {src/name/branch/opts...}），
--- 其中一条含 opts.colorscheme（LazyVim 键）标定要应用的主题。
---@return string colorscheme, table[] theme_specs
local function parse(spec)
  assert(type(spec) == "table", ("Omarchy theme spec 不是 table（got %s）"):format(type(spec)))
  local colorscheme, theme_specs = nil, {}
  for i, item in ipairs(spec) do
    if type(item) == "table" then
      if item.opts and item.opts.colorscheme then
        colorscheme = item.opts.colorscheme
      elseif item[1] then
        theme_specs[#theme_specs + 1] = item
      elseif item.src then
        theme_specs[#theme_specs + 1] = item
      else
        error(
          ("Omarchy theme spec 第 %d 项结构未知（无 [1]/src/opts.colorscheme），上游格式可能已变"):format(
            i
          )
        )
      end
    elseif type(item) == "string" then
      theme_specs[#theme_specs + 1] = { src = item }
    else
      error(("Omarchy theme spec 第 %d 项类型未知: %s"):format(i, type(item)))
    end
  end
  assert(
    colorscheme and #colorscheme > 0,
    "Omarchy theme spec 缺少 opts.colorscheme（LazyVim 段），上游格式可能已变"
  )
  return colorscheme, theme_specs
end

--- 上游 spec → vim.pack spec（name 默认取 repo 名；branch → version）。
local function to_pack_spec(item)
  local src = item.src or item[1]
  assert(type(src) == "string", "主题插件条目缺 src")
  return {
    src = src,
    name = item.name,
    version = item.branch,
    -- opts 留在 data 里，load 时交还给主题插件 setup
    data = item.opts,
  }
end

--- 应用当前主题（幂等；watcher 与启动共用）。
--- opts.force 跳过 mtime 去重（watcher 侧用：theme/ 与 theme.name 两次
--- 事件若超 debounce 会双重触发，同 spec 重复应用会闪屏）。
---@param opts? { replay_transparency?: boolean, force?: boolean }
---@return boolean ok
function M.load(opts)
  opts = opts or {}
  local readable = vim.fn.filereadable(SPEC_PATH) == 1
  if not readable then
    -- 非 Omarchy 机器（多机场景）：静默回退到 colorscheme.lua 的静态应用
    return false
  end

  -- mtime+size 去重：同内容重复事件直接跳过（声明须在赋值点前，
  -- 否则 Lua 把赋值当全局、成功时读到 nil 指纹）
  local pending_fingerprint
  local stat = uv.fs_stat(SPEC_PATH)
  if stat then
    local fingerprint = stat.mtime.sec .. ":" .. stat.mtime.nsec .. ":" .. stat.size
    if not opts.force and fingerprint == state.last_fingerprint then
      return true
    end
    pending_fingerprint = fingerprint
  end
  local ok, spec = pcall(dofile, SPEC_PATH)
  if not ok then
    vim.notify(
      "Omarchy theme spec 解析失败:\n" .. tostring(spec),
      vim.log.levels.ERROR,
      { title = "omarchy-theme" }
    )
    return false
  end
  local parse_ok, colorscheme, theme_specs = pcall(parse, spec)
  if not parse_ok then
    -- 断言兑底：上游结构变化必须显式报错不静默（问题5 结论）
    vim.notify(
      "Omarchy theme spec 结构断言失败:\n" .. tostring(colorscheme),
      vim.log.levels.ERROR,
      { title = "omarchy-theme" }
    )
    return false
  end

  -- 主题插件必须在位（themes.lua 预装了全部 20 件；Omarchy 4 通用主题
  -- aether 也在其中。未装的按需 add——confirm=false 避免阻塞）。
  local pack_specs = {}
  for _, item in ipairs(theme_specs) do
    pack_specs[#pack_specs + 1] = to_pack_spec(item)
  end
  if #pack_specs > 0 then
    local add_ok, add_err = pcall(vim.pack.add, pack_specs, { confirm = false })
    if not add_ok then
      vim.notify("主题插件安装失败:\n" .. tostring(add_err), vim.log.levels.ERROR, { title = "omarchy-theme" })
      return false
    end
  end

  -- opts.colors 形态（Omarchy 4 的 aether 通用主题）：setup 注入调色板
  for _, item in ipairs(theme_specs) do
    local pack = to_pack_spec(item)
    if type(pack.data) == "table" and pack.data.colors then
      local mod_name = pack.name or pack.src:gsub(".*/", ""):gsub("%.nvim$", "")
      local mod_ok, mod = pcall(require, mod_name)
      if mod_ok and type(mod.setup) == "function" then
        pcall(mod.setup, pack.data)
      end
    end
  end

  -- 应用 colorscheme。catppuccin-nvim 等别名经其 colors/ 入口落到实际 flavor
  --（基线同机制：apply 后 colors_name = catppuccin-mocha）。
  local cs_ok, cs_err = pcall(vim.cmd.colorscheme, colorscheme)
  if not cs_ok then
    vim.notify(
      ("colorscheme %s 应用失败:\n%s"):format(colorscheme, tostring(cs_err)),
      vim.log.levels.ERROR,
      { title = "omarchy-theme" }
    )
    return false
  end

  -- 透明度重应用（热重载路径；启动路径由 plugin/after 正常执行一次）
  if opts.replay_transparency and vim.fn.filereadable(TRANSPARENCY) == 1 then
    pcall(vim.cmd.source, TRANSPARENCY)
  end

  -- 通知 UI 侧刷新（对齐原 omarchy-theme-hotreload 的收尾动作）
  vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
  if opts.replay_transparency then
    vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })
  end
  vim.cmd("redraw!")
  -- 成功才落指纹：解析/应用失败时下次事件可重试
  state.last_fingerprint = pending_fingerprint
  return true
end

local function fire()
  M.load({ replay_transparency = true })
end

--- debounce：切主题时上游连续写入（theme.name/theme/ 两个事件）坍缩为一次 load。
local function schedule_fire()
  if not state.timer then
    state.timer = uv.new_timer()
  end
  state.timer:stop()
  state.timer:start(1500, 0, function()
    vim.schedule(fire)
  end)
end

local function on_event(err, filename, _)
  if err then
    -- 句柄出错：销毁重挂（父目录 current/ 若也被重建则本句柄已死）
    vim.schedule(function()
      if state.handle then
        pcall(function()
          state.handle:stop()
          state.handle:close()
        end)
        state.handle = nil
      end
      M.watch()
    end)
    return
  end
  -- 只关心 theme 与 theme.name（current/ 下还有 background 等无关项）
  if filename == "theme" or filename == "theme.name" then
    schedule_fire()
  end
end

--- 连续 start 失败上限：目录永久缺失（非 Omarchy 机器，多平台常态）达限即
--- 放弃，不再每 2s 空转；上限内的重试仍用于容忍切主题 rm -rf 间隙。
M.MAX_START_FAILURES = 3

--- watch 父目录 current/（theme 子项的 rm -rf+mv 替换在其下产生事件）。
function M.watch()
  if state.handle then
    return
  end
  local handle = uv.new_fs_event()
  if not handle then
    vim.notify(("无法 watch %s"):format(OMARCHY_STATE), vim.log.levels.WARN, { title = "omarchy-theme" })
    return
  end
  local ok, err = handle:start(OMARCHY_STATE, {}, on_event)
  if not ok then
    pcall(function()
      handle:close()
    end)

    -- 连续失败达上限：静默放弃（启动期 load() 已兜底应用主题，仅热重载失效）
    state.failures = (state.failures or 0) + 1
    if state.failures >= M.MAX_START_FAILURES then
      return
    end

    -- current/ 可能短暂不存在（rm -rf 间隙）：延时重挂
    if not state.rearm_timer then
      state.rearm_timer = uv.new_timer()
    end
    state.rearm_timer:stop()
    state.rearm_timer:start(2000, 0, function()
      vim.schedule(function()
        state.rearm_timer:stop()
        M.watch()
      end)
    end)
    if err then
      return
    end
    return
  end
  state.failures = 0
  state.handle = handle
end

return M
