local languages = {}

Language = {}

---@param language string
function Language:new(language)
  local instance = setmetatable({}, { __index = self })
  languages[language] = instance
  return instance
end

---@param config table<string, any>
function Language:mason(config)
  self.mason_config = config
  return self
end

---@param config table<string, any>
function Language:lspconfig(config)
  self.lspconfig_config = config
  return self
end

---@param config table<string, { install: boolean }>
function Language:conform(config)
  self.conform_config = config
  return self
end

---@param config string
function Language:treesitter(config)
  self.treesitter_config = config
  return self
end

Language:new("angular"):mason({ ["angular-language-server"] = {} })

Language:new("astro"):mason({ ["astro-language-server"] = {} }):conform({ prettierd = { install = true } })

Language:new("css"):mason({ ["css-lsp"] = {} }):conform({ prettierd = { install = true } })

Language:new("diff")

Language:new("html"):conform({ prettierd = { install = true } })

Language:new("luadoc")

Language:new("markdown")

Language:new("markdown_inline")

Language:new("query")

Language:new("vim")

Language:new("vimdoc")

Language:new("elm"):mason({ ["elm-language-server"] = {} }):conform({ "elm_format" })

Language:new("gleam"):conform({ "gleam" }):lspconfig({ gleam = {} })

Language:new("javascript"):mason({ ["js-debug-adapter"] = {} }):conform({ prettierd = { install = true } })

Language:new("json"):conform({ prettierd = { install = true } })

Language:new("jsonc"):conform({ prettierd = { install = true } })

Language:new("typescript")
  :mason({
    eslint = {
      {
        on_attach = function(_, bufnr)
          vim.api.nvim_create_autocmd("BufWritePre", {
            buffer = bufnr,
            command = "EslintFixAll",
          })
        end,
      },
    },
  })
  :conform({ prettierd = { install = true } })

Language:new("lua")
  :mason({
    lua_ls = {
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
        },
      },
    },
    stylua = {},
  })
  :conform({ stylua = { install = true } })

Language:new("ruby"):mason({ ruby_lsp = {} }):conform({ "rubocop" })

Language:new("rust")
  :mason({
    rust_analyzer = {
      settings = {
        ["rust-analyzer"] = {
          check = {
            command = "clippy",
          },
        },
      },
    },
  })
  :conform({ "rustfmt" })

Language:new("sh")
  :mason({
    shellcheck = {},
    ["bash-language-server"] = {},
  })
  :conform({ shfmt = { install = true } })
  :treesitter("bash")

Language:new("sql"):mason({
  sqlfmt = {},
  sqlls = {},
})

Language:new("kdl"):conform({ "kdlfmt" })

Language:new("other"):mason({
  ["harper-ls"] = {},
})

return languages
