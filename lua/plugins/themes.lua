-- 主题插件清单：基线 all-themes.lua 的 vim.pack 等效（全部预装，
-- 供 Omarchy 切主题时零安装切换）。
-- name/branch 特例必须与 Omarchy 生成的 theme spec 一致
-- （default/themed/neovim.lua.tpl：aether 用 branch v3 + name aether）。
return {
  { src = "https://github.com/ribru17/bamboo.nvim", name = "bamboo.nvim" },
  { src = "https://github.com/bjarneo/aether.nvim", name = "aether", version = "v3" },
  { src = "https://github.com/bjarneo/ethereal.nvim", name = "ethereal.nvim" },
  { src = "https://github.com/bjarneo/hackerman.nvim", name = "hackerman.nvim" },
  { src = "https://github.com/bjarneo/vantablack.nvim", name = "vantablack.nvim" },
  { src = "https://github.com/bjarneo/white.nvim", name = "white.nvim" },
  { src = "https://github.com/ellisonleao/gruvbox.nvim", name = "gruvbox.nvim" },
  { src = "https://github.com/rebelot/kanagawa.nvim", name = "kanagawa.nvim" },
  { src = "https://github.com/tahayvr/matteblack.nvim", name = "matteblack.nvim" },
  -- 上游 gthelding/monokai-pro.nvim 已删（基线 URL 现 404），
  -- 同 commit 存在于原仓库 loctvl842/monokai-pro.nvim
  { src = "https://github.com/loctvl842/monokai-pro.nvim", name = "monokai-pro.nvim" },
  { src = "https://github.com/EdenEast/nightfox.nvim", name = "nightfox.nvim" },
  { src = "https://github.com/rose-pine/neovim", name = "rose-pine" },
  { src = "https://github.com/ficcdaf/ashen.nvim", name = "ashen.nvim" },
  { src = "https://github.com/OldJobobo/miasma.nvim", name = "miasma.nvim" },
  { src = "https://github.com/OldJobobo/retro-82.nvim", name = "retro-82.nvim" },
  { src = "https://github.com/omacom-io/lumon.nvim", name = "lumon.nvim" },
  { src = "https://github.com/neanias/everforest-nvim", name = "everforest-nvim" },
  { src = "https://github.com/kepano/flexoki-neovim", name = "flexoki-neovim" },
}
