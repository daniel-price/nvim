-- This module defines language-specific config, then exports fully-aggregated
-- data structures consumed by plugin setup:
-- - `treesitter_installs`: list of parsers
-- - `mason_tools`: map of mason packages to config (also used to derive ensure_installed)
-- - `lsp_servers`: map of lsp server name -> opts for vim.lsp.config()
-- - `formatters_by_ft`: conform.nvim formatters_by_ft

vim.filetype.add({
  extension = {
    herb = "html",
  },
})

---@class LanguageConfig
---@field treesitter? string
---@field mason? table<string, any>
---@field lsp? table<string, any>
---@field conform? table<any, any> -- supports both list-style { "tool" } and map-style { tool = { install = true } }

---@type table<string, LanguageConfig>
local langs = {
  angular = {
    mason = {
      ["angular-language-server"] = {},
    },
  },
  astro = {
    mason = {
      ["astro-language-server"] = {},
    },
    conform = {
      prettierd = {
        install = true,
      },
    },
  },
  css = {
    mason = {
      ["css-lsp"] = {},
    },
    conform = {
      prettierd = {
        install = true,
      },
    },
  },
  diff = {},
  html = {
    conform = {
      prettierd = {
        install = true,
      },
    },
  },
  luadoc = {},
  markdown = {},
  markdown_inline = {},
  query = {},
  vim = {},
  vimdoc = {},
  elm = {
    mason = {
      ["elm-language-server"] = {},
    },
    conform = {
      "elm_format",
    },
  },
  gleam = {
    lsp = {
      gleam = {},
    },
    conform = {
      "gleam",
    },
  },
  javascript = {
    mason = {
      ["js-debug-adapter"] = {},
    },
    conform = {
      prettierd = {
        install = true,
      },
    },
  },
  json = {
    conform = {
      prettierd = {
        install = true,
      },
    },
  },
  jsonc = {
    conform = {
      prettierd = {
        install = true,
      },
    },
  },
  typescript = {
    mason = {
      ["typescript-language-server"] = {},
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
    },
    conform = {
      prettierd = {
        install = true,
      },
    },
  },
  lua = {
    mason = {
      lua_ls = {
        settings = {
          Lua = {
            completion = { callSnippet = "Replace" },
          },
        },
      },
      stylua = {},
    },
    conform = {
      stylua = {
        install = true,
      },
    },
  },
  ruby = {
    mason = {
      ruby_lsp = {},
    },
    conform = {
      -- rubyfmt = {
      --   install = true,
      -- },
    },
  },
  rust = {
    mason = {
      rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            check = { command = "clippy" },
          },
        },
      },
    },
    conform = {
      "rustfmt",
    },
  },
  sh = {
    treesitter = "bash",
    mason = {
      shellcheck = {},
      ["bash-language-server"] = {},
    },
    conform = {
      shfmt = {
        install = true,
      },
    },
  },
  sql = {
    mason = {
      sqlfmt = {},
      sqlls = {},
    },
  },
  kdl = {
    conform = {
      "kdlfmt",
    },
  },

  -- extra tools / servers with no treesitter ft config
  other = {
    mason = {
      ["harper-ls"] = {},
      ["herb-language-server"] = {},
    },
  },

  -- Used by vim's builtin ft detection for .ejs etc; keep lsp config here.
  embedded_template = {
    lsp = {
      herb_ls = {
        cmd = { "herb-language-server", "--stdio" },
        filetypes = { "ruby", "eruby", "herb" },
        root_markers = { "Gemfile", ".git" },
      },
    },
  },
}

local M = {
  ---@type string[]
  treesitter_installs = {},
  ---@type table<string, any>
  mason_tools = {},
  ---@type table<string, any>
  lsp_servers = {},
  ---@type table<string, string[]>
  formatters_by_ft = {},
  formatters = {},
}

for ft, cfg in pairs(langs) do
  if ft ~= "other" then
    table.insert(M.treesitter_installs, cfg.treesitter or ft)
  end

  if cfg.mason then
    for tool, opts in pairs(cfg.mason) do
      M.mason_tools[tool] = opts
    end
  end

  if cfg.lsp then
    for server, opts in pairs(cfg.lsp) do
      M.lsp_servers[server] = opts
    end
  end

  if cfg.conform then
    M.formatters_by_ft[ft] = {}

    for key, value in pairs(cfg.conform) do
      -- list-style: { "rubocop" }
      if type(key) == "number" then
        if type(value) ~= "string" then
          error(ft .. ": formatter must be a string, got: " .. type(value))
        end
        table.insert(M.formatters_by_ft[ft], value)
      else
        -- map-style: { prettierd = { install = true } } OR { prettierd = "prettierd" }
        if type(value) == "table" then
          if value.install then
            if type(key) ~= "string" then
              error(ft .. ": formatter name must be a string, got: " .. type(key))
            end
            M.mason_tools[key] = M.mason_tools[key] or {}
          end

          if value.props then
            -- conform.nvim formatter config
            M.formatters[key] = value.props
          end
          table.insert(M.formatters_by_ft[ft], key)
        else
          if type(value) ~= "string" then
            error(ft .. ": formatter must be a string, got: " .. type(value))
          end
          table.insert(M.formatters_by_ft[ft], value)
        end
      end
    end
  end
end

return M
