-- mini.ai：文本对象扩展。行为源：LazyVim plugins/coding.lua 的 mini.ai spec。
-- 差异：which-key 注册原走 LazyVim.on_load（lazy 加载事件）；vim.pack 全量加载下
-- 延后到 VimEnter 后注册（此时 which-key setup 已完成）。
return {
  src = "https://github.com/nvim-mini/mini.ai",
  name = "mini.ai",
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
    vim.schedule(function()
      require("meow").mini.ai_whichkey(opts)
    end)
  end,
}
