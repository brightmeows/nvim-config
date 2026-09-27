-- mini.ai：文本对象扩展。行为源：LazyVim plugins/coding.lua 的 mini.ai spec
-- （event=VeryLazy；which-key 注册与基线同在加载期直调——LazyVim 在 opts
-- 函数里调 ai_whichkey，此处 config 内直调，时序同为 VeryLazy 加载批）。
return {
  "https://github.com/nvim-mini/mini.ai",
  event = "VeryLazy",
  config = function()
    local ai = require("mini.ai")
    local opts = {
      n_lines = 500,
      custom_textobjects = {
        o = ai.gen_spec.treesitter({ -- code block
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }),
        f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
        c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
        t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
        d = { "%f[%d]%d+" }, -- digits
        e = { -- Word with case
          { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
          "^().*()$",
        },
        g = require("meow").mini.ai_buffer, -- buffer
        u = ai.gen_spec.function_call(), -- u for "Usage"
        U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
      },
    }
    ai.setup(opts)
    require("meow").mini.ai_whichkey(opts)
  end,
}
