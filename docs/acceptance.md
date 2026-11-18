# 验收清单：vim.pack → lazy.nvim 切换

逐项核对切换前（tag `vim-pack-final`，vim.pack 驱动终态）与切换后的状态。
行为源不变，仍为 LazyVim 16.0.0：**恢复项** = 相对 vim.pack 终态回归基线语义
（预期可见变化）；**保留差异** = 相对基线仍存在、已确认接受的偏离；行为内容
域（选项、autocmd、键位、LSP 等）本次未改，清单项延续核对。依赖 CI 的条目以
流水线首绿为准，不提前勾选。

对照物（本机在档）：

- LazyVim 16.0.0 源码：`~/.local/share/nvim/lazyvim-ref/lua/lazyvim/`
- 切换前终态：tag `vim-pack-final`（回退锚点）
- 基线启动数据：LazyVim 16.0 + lazy.nvim 11.17.5 中位约 56ms；
  vim.pack 终态中位约 164ms（均为本机六次 `--startuptime` 中位）

## 一、切换与装配

- [x] `nvim --headless` 退出码 0、输出无 Error（弱 smoke 与强测各一次）
- [x] lazy spec 50 件（49 插件 + lazy.nvim）全部识别，lazy 根无游离目录
- [x] 启动即应用当前主题（经上游 spec 注入与 ColorSchemePre 加载，colors_name = catppuccin-mocha）
- [x] 无 vim.pack 残留（`rg 'vim.pack|nvim-pack'` 对 lua/init/plugin/scripts 清零；
  nvim-pack-lock.json 与 packcheck 已随切换批次删除）
- [x] CI lint / 三平台强测 / lockfile 全新安装三绿（首绿 run 36301007177）
- [x] 干净机器全新安装逐 rev 校验（CI lockfile job 同 run 绿：全新安装 +
  `verify-lockfile` 50/50；本机对拍亦 50/50）

## 二、懒加载恢复（恢复项，行为源 LazyVim 16.0 触发映射）

触发映射逐件回填：lsp 走 BufReadPre/BufNewFile，gitsigns/lint/autotag 走
LazyFile，treesitter 走 LazyFile/VeryLazy 加 cmd，lualine/bufferline/noice/
which-key/flash/mini 系/ts-comments/textobjects 走 VeryLazy，persistence 走
BufReadPre，blink 走 InsertEnter/CmdlineEnter，mason/conform/trouble/grug-far/
neo-tree/todo-comments 走 cmd 加 keys，lazydev 走 ft 加 cmd，主题件与
colorscheme 件走 lazy=true。

- [x] 强测 `scripts/strong-smoke.lua`：50/50 载入、无 Error（headless 手动触发
  VeryLazy/LazyFile/文件事件 + 程序化补载双保险）
- [x] `<leader>l` = `:Lazy`（desc "Lazy"，基线原样）；dashboard `l` = `:Lazy`
- [x] `[q`/`]q` = trouble 版本（safe_keymap_set 探测到 keys handler 后跳过，
  与基线同机制）
- [x] `<S-h>` = bufferline 版本（keys handler 生效，基线同机制；vim.pack 终态
  为 keymaps 的 bprevious，属恢复项）
- [x] VeryLazy 链路：keymaps/autocmds/format/root setup 于 VeryLazy 执行
  （`:LazyFormat` 存在、formatter 已注册）
- [x] 键位抽查齐全：`<leader>xx / sr / qs / fe / , / ?`
- [x] `<leader>gj`/`<leader>gJ` = jjui 浮窗（Snacks.terminal，executable 守卫；
  Root Dir 走 `meow.root.git()`；自增功能非复刻项）
- [x] mason 的 cmd/keys/build 与安装后 FileType 重触发恢复；mason-lspconfig
  以依赖占位空 config 形态回归（LazyVim 同构）
- [ ] 打开文件触发 BufReadPre 链（lsp、mason 随依赖加载）与 LazyFile 链
  （gitsigns 行标记、lint、autotag）实操无回归
- [ ] 事件件实操：lualine/bufferline 在 VeryLazy 后出现、`:Mason`、`:ConformInfo`、
  `<leader>cF`、neo-tree 目录参数启动、`<leader>qs` 会话恢复
- [ ] blink 仅在插入/命令行进入时加载（首键输入无报错）

## 三、主题与 Omarchy 耦合

- [x] 热重载：running 实例切 Gruvbox 后 6.1s 跟随、切回 Catppuccin 后 13.8s
  跟随，两程 Normal 背景保持透明（透明度重放生效）；切回后新实例启动主题正确
- [x] 断言兜底：破坏上游 spec 启动报错可见（messages 含解析失败全文），并按
  静态回退应用 catppuccin（与切换前失败分支行为一致）
- [x] 缺件策略：上游 spec 指向未预装插件时，启动注入报错、条目跳过、不触发
  安装（lazy 根无该目录）；热重载路径同口径报错
- [x] 注入条目与 themes.lua/colorscheme.lua 预装集按 URL 对齐（rose-pine/
  aether/catppuccin 特例 name/branch 保留）

## 四、锁、多机与对齐守卫

- [x] `lazy-lock.json` 50 条（49 插件按切换前 rev + lazy.nvim 85c7ff3），本地
  `nvim -l scripts/verify-lockfile.lua` 逐件 HEAD 全等
- [x] 对齐守卫：人为把锁改错 1 件后启动，WARN 提示“盘上/锁不一致，执行
  :Lazy restore”可见；还原后一轮静默通过
- [x] 新机/首启按锁装齐的机制核对（lazy 启动安装带 lockfile=true，
  lazy 源码 loader.lua:84）
- [ ] 第二台机器实拉演练：拉取 → 守卫提示 → `:Lazy restore` → 复检静默

## 五、性能

- [x] 本机 `--startuptime` 中位 **29.4ms**（2026-11-14 五次：27.5 / 28.9 /
  29.4 / 29.5 / 29.5），低于 100ms 门槛。历史：切换后 32.1ms；22e3770 的
  首克隆对齐误做成每次启动 checkout，中位升至 261 至 340ms，收窄到首克隆
  分支后回落
- [x] 启动闸门 `nvim -l scripts/startup-gate.lua` 通过：五次中位不超基线
  1.5 倍加 20ms，基线存 `scripts/startup-baseline.json`；仅本机执行
- [x] dashboard 页脚为原生 lazy.stats：伪 TUI（80x35）实测
  “Neovim loaded 3/50 plugins in 35.13ms”

## 六、UI 与 dashboard（伪 TUI 实测）

- [x] dashboard 九键齐全（f/n/g/r/c/s/p/l/q），头图完整，`q` 退出码 0
- [x] `:Lazy` 命令存在；UI 打开实操一次后再勾详情
- [ ] `:Lazy` 更新流程实操（update 审阅与锁文件回写）

## 七、质量闸门

- [x] `pre-commit run --all-files`（stylua + selene）全绿、0 告警
- [x] CI 全绿（首绿 run 36301007177）：lint、三平台强测 smoke、lockfile
  全新安装与逐 rev 校验
- [x] pre-push 行为闸门全绿（自判 smoke、meow 单元、锁与 spec 双向）
- [x] `commit-msg` 骨架校验生效（合规通过、不合规阻断）
- [x] 文档命令串同源检查通过（`scripts/check-docs-sync.lua`）
- [x] 新增 job 首绿（run 43573387937）：docs 同源、三平台 smoke 含单元、
  lockfile、nightly（仅报告）
- 注：runner 无 `tree-sitter` CLI，smoke job 经 npm 预装；mason 等异步安装
  收敛在不设闸的安装步完成（`scripts/settle-installs.lua`，本地与 CI 同源），
  强测步零在途安装（首跑失败根因已记录于 ci 提交 d663a0a）

## 八、全局选项

来源：LazyVim `config/options.lua` + 基线覆盖项。本次未改，延续核对：

- [ ] `mapleader = " "`、`maplocalleader = "\"`
- [ ] `autoformat = false`、`relativenumber = false`
- [ ] remote_clipboard 在 options 加载早期生效（`vim.g.clipboard`）
- [ ] 基线选项全表逐项一致（`autowrite`、`clipboard`、`completeopt`、
  `conceallevel=2`、`cursorline`、`fillchars`、`foldlevel=99`、`grep` 走 `rg`、
  `laststatus=3`、`sessionoptions`、`timeoutlen=300`、`undofile`、`updatetime=200`、
  `wrap=false` 等，完整清单以 `lua/config/options.lua` 为准）
- [ ] `statuscolumn` 与 `formatexpr` 走 meow 层（conform 按 spec 存在性选路）
- [ ] snacks scroll 动画关闭

## 九、自动命令

来源：LazyVim `config/autocmds.lua`；加载时机为 argc>0 早加载、否则 VeryLazy
（本次恢复的时序）。

- [ ] checktime、highlight on yank、VimResized 等分
- [ ] BufReadPost 回到最后编辑位置（gitcommit 除外）
- [ ] 关闭类 filetype 用 `q` 退出；man 文件不入 buffer 列表
- [ ] text/markdown/gitcommit 自动 wrap + spell；json/jsonc conceallevel=0
- [ ] BufWritePre 自动创建父目录
- [x] vim.pack 确认页提示 autocmd 已随切换删除

## 十、Keymaps

来源：LazyVim `config/keymaps.lua` + extras；本次仅改加载时机与时序机制，
键位内容未改。

- [x] `<leader>l` 回归 `:Lazy`；`[q`/`]q` 恢复基线行（由 safe_keymap_set
  探测让位 trouble 版本）
- [ ] 方向键 `gj`/`gk`、窗口导航、`<A-j/k>` 移行、buffer 组、`<esc>` 智能退出
- [ ] toggle 组 `<leader>u*`、git 组 `<leader>g*`、picker 组、neo-tree 组
  `<leader>fe/fE/e/E/ge/be`、flash 组 `s/S/r/R`、trouble 组、todo 组
- [ ] grug-far `<leader>sr`、conform `<leader>cF`、mason `<leader>cm`
- [ ] which-key 分组标签与基线一致；`<localleader>r`、`<c-/>` 终端
- [ ] LazyVim 专有引用（`LazyVim.*`）在 meow 命名空间等效且行为一致

## 十一、LSP 与补全

- [ ] mason 管理 lua-language-server、shfmt、stylua（首开 lua 文件后按链加载）
- [ ] `servers` 表是默认候选集：`lua_ls` 始终启用，其余 server 仅在
  `cmd_available` 通过时启用；`mason-lspconfig` 的 `automatic_enable = false`，
  mason 只保证 `lua_ls`，其余需本机已装
- [ ] 未装 server 不进入启用集；picker 的 installed 列可辨，打开对应文件不报错
- [ ] LSP 键位（`gd/grr/gI/gy/gD`、`K/gK`、`<leader>c*`、`]]/[[`、`<a-n/p>`）
  含 `has` 条件逐个生效；`grr` 保留 Neovim 原生 `grn/gra` 前缀
- [ ] `<leader>cl` 在无 client 时可打开 LSP picker；面板 `<c-t>` 启停、`<c-r>` 重启，
  启停后现有 buffer 由 `vim.lsp.enable` 的 doautoall 补挂
- [ ] lualine `lsp_status` 显示活动 client 数量与进度（`show_name = false`）
- [ ] inlay hints、diagnostics 显示与基线一致；`<leader>cd` 行内诊断浮动
- [ ] blink `<C-Space>`、Enter/Tab 确认、friendly-snippets 片段、lazydev 库补全

## 十二、格式化与 Lint

- [ ] conform：lua → stylua、sh → shfmt、`<leader>cF` 注入格式化
- [ ] `autoformat = false` 下保存不触发；`<leader>cf` 与 `:LazyFormat` 可用
  （formatter 在 VeryLazy 注册）
- [ ] nvim-lint 事件触发（fish 基线仅配 fish）

## 十三、Treesitter

- [ ] parser 列表与基线一致（`TSUpdate` 不报错）
- [ ] highlight/indent/folds 生效；textobjects 与 autotag 生效
- [ ] 加载时机：LazyFile/VeryLazy（含 cmd 直达 `TSUpdate` 等）

## 十四、UI 组件

- [ ] lualine：状态栏在 VeryLazy 后出现（init 的 laststatus 时序恢复）、
  更新计数走 `lazy.status`（checker notify=false 只呈现不通知）、trouble 文档符号
- [ ] bufferline VeryLazy + keys 触发；catppuccin 集成经 specs 段合并
- [ ] noice/which-key/gitsigns/todo-comments/persistence/ts-comments/mini 系
  （对照各自触发件实操）
- [ ] snacks：notify、terminal、indent、toggle 与基线一致
- [ ] neo-tree：`<leader>e` 打开、三源、`l/h`、`Y/O/P`
- [ ] 启动 dashboard（见第六节）

## 十五、自定义件

- [ ] remote_clipboard：Wayland / tmux 缓冲 / SSH 分支（粘贴不回询
  OSC 52，读取兜底本实例 last_copy；复制在 tmux 内经 load-buffer 发出）
- [ ] `plugin/after/transparency.lua` 每次启动生效
- [ ] 会话 persistence `<leader>qs/qS/ql/qd`

## 十六、保留差异（相对 LazyVim 16.0 基线，延续既有接受）

- LazyVim Changelog（`<leader>L`）→ Neovim news（发行版概念已移除）
- dashboard 的 `x` 键（`:LazyExtras`）移除（extras 概念不存在）
- remote_clipboard 在 options 早期生效（基线 VeryLazy 时序的既有偏离，本次未动）
- remote_clipboard 采用 Omarchy 上游策略：粘贴只读 Wayland 与 tmux 缓冲，
  不回询 OSC 52（读取失败兜底本实例 last_copy）；setup 内的 unnamedplus
  同步被 options.lua 的基线赋值覆盖，SSH 下 clipboard 仍为空串
- 非 Omarchy 机器的静态回退主题由 `meow.theme.load` 触发（机制换了、失败
  分支行为与切换前一致）
- `gr` 改为 `grr`（基线 snacks_picker 用 `gr`），保留 Neovim 原生 `grn/gra` 前缀
- `<leader>cl` 全局可用（基线仅在 client attach 后可用），面板增加 `<c-t>` 启停与
  `<c-r>` 重启
- 默认启用集扩为 `lua_ls、rust_analyzer、clangd、ts_ls、bashls、marksman`；
  `lua_ls` 始终启用，其余仅在本机可执行文件存在时启用

## 十七、非目标（本次不做，显式点名）

- 不增删插件（49 件集合不变）；对照源码不升 16.0.1，行为源仍 16.0.0
- Neovim 0.12+ 与三平台分级声明不变；AGENTS 行为源纪律、pre-commit 与提交规范不变
- 100ms 性能门槛仅本机执行，不进 CI（runner 噪声）
- LazyVim 发行版回归路线本次不做，日后另议

## 十八、清理与交付

- [x] `nvim-pack-lock.json` 与 `lua/meow/packcheck.lua` 已删除（清理批次）
- [x] 全仓 `rg 'vim.pack|nvim-pack|问题[0-9]'` 对产出物清零（含注释中的
  盘问编号——产物边界）
- [x] README/AGENTS 已同步 lazy 口径（锁名、更新命令、强测命令）
- [x] 清理批次推送、CI 首绿（run 36301007177；分四批：切换本体、ci、docs、ci 修复）
- [x] `~/.local/share/nvim/site/pack` 已移出并删除（vim.pack 启动会自动重写
  nvim-pack-lock.json，移出后不再再生；129M 备份在 CI 首绿后删除，
  插件可由 git 远端重装，回退锚点为 tag `vim-pack-final`）

## 十九、自增功能：接口大纲、完整 diff、工作树

第十七节的“49 件集合不变”是 lazy 切换任务的范围；本节是其后新增的功能，
显式打破该集合。当前 `lazy-lock.json` 52 条（51 插件 + lazy.nvim），行为源
仍是 LazyVim 16.0，新增件标为自增。

### 接口大纲与项目 API

- [x] `outline.nvim` 接管 `<leader>cs`，右侧栏打开，LSP `detail` 作为虚拟文本；
  trouble symbols 改由 `:Trouble symbols` 进入，trouble 其余键与 lualine 符号不变。
- [x] 当前文件过滤沿用 `meow.kind_filter`，保留 Field 与 Property；outline 打开
  不抢焦点；LSP client 晚于 outline 打开时，`LspAttach` 触发 refresh，并在
  2s 与 8s 各补一次重试（headless 验证）。
- [x] `<leader>sA` 打开项目 API 符号，严格过滤 Class、Constructor、Enum、
  Function、Interface、Method、Module、Namespace、Struct、Trait；lua 排除
  Package；格式化附带 `detail`。
- [x] `<leader>ss` 与 `<leader>sS` 仍为全量，行为未变。
- [x] 补充键位：`<leader>cT` trouble symbols、`<leader>cO` outline focus、
  `<leader>gC` git branches、`<leader>gT` diffview toggle、`<leader>gO` diffview log、
  `<leader>sI` LSP declarations、`<leader>sP` pickers、`<leader>uB` line blame toggle。
  `sI` 始终注册；server 不支持 declaration 时列表为空。
- [ ] TUI 实操：outline 的 preview、hover、跳转与折叠。

### 完整 diff

- [x] `diffview-plus.nvim` 接管 `<leader>gv`（`:DiffviewOpen`）与
  `<leader>gV`（`:DiffviewFileHistory %`）。
- [x] 文件面板 `<cr>`、`<tab>`、`gf`、`-`、`g<C-x>` 用插件默认键位。
- [x] snacks 的 `<leader>gd`、`<leader>gD` 与 gitsigns 的 `<leader>gh*` 保留。
- [ ] TUI 实操：文件面板切文件、单文件 diff、stage 与布局切换。

### 工作树

- [x] `<leader>gw` 打开 `:DiffviewWorktreeOverview`；临时仓库两项工作树
  均列出，含 ahead/behind、numstat 与 dirty 计数。
- [x] `<leader>gW` 与 `:WorktreeSwitch` 走 `meow.worktree`：解析
  `git worktree list --porcelain`，跳过 bare 与 prunable，切换后打开同名文件，
  找不到时打开目标目录文件选择器；不重启 LSP。
- [x] 解析器单元测试覆盖主树、斜杠分支、detached、locked、prunable、bare、
  CRLF 与无尾空行。
- [ ] TUI 实操：picker 选中切换、同名文件命中与未命中两条分支。

### LSP 面板与状态栏

- [x] `<leader>cl` 全局可用，打开 Snacks `lsp_config` 面板；无 client 时也能管理。
- [x] 面板 `<c-t>` 启停、`<c-r>` 重启；启停走 `vim.lsp.enable`，现有 buffer 由
  Neovim 的 doautoall 补挂，不再手动触发 FileType。
- [x] `servers` 表是默认候选集：`lua_ls` 始终启用，其余按 `cmd_available` 过滤；
  函数式 `cmd`（`ts_ls`）按可用处理，缺件由 picker 的 installed 列提示。
- [x] lualine `lsp_status` 放到 `lualine_x` 首位，`show_name = false`，显示活动
  client 数量与进度。
- [ ] TUI 实操：无 client 开面板、启停与重启各一次、缺件 server 显示。

### 闸门

- [x] `lazy-lock.json` 52 条；`scripts/verify-lockfile.lua` 52/52，spec 图 51 件。
- [x] `scripts/strong-smoke.lua` 52/52 载入，无 Error。
- [x] `scripts/test-meow.lua` 67 项通过。
- [x] `stylua --check .` 与 `selene lua init.lua plugin scripts` 全绿。
- [x] 启动闸门通过：27.5/30.6/32.6/35.7/48.6，中位 32.6ms，低于 64.1ms 阈值；
  负载高时曾测 76.8ms，基线提交同测 73.6ms，未改基线。
- [x] CI 首绿（run 43614005752）：lint、三平台 smoke、lockfile、docs 全绿。

### 否决项

- aerial：不显示 LSP `detail`。
- 上游 `sindrets/diffview.nvim`：停更。
- `codediff.nvim`：原生二进制不受锁管理。
- `neogit`：体量大，和 lazygit 重叠。
- `awerebea/git-worktrees.nvim`、`Juksuu/worktrees.nvim`：对“只切 cwd”超出需求。
