---------------------
----- CONSTANTS -----
---------------------

local DEBUG = false

local COPILOT_NODE_PATH = vim.fn.expand("$HOME") .. "/.asdf/installs/nodejs/22.14.0/bin/node"

---------------------
------ OPTIONS ------
---------------------

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true

-- Enable mouse mode
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
-- Schedule the setting after `UiEnter` because it can increase startup-time.
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

-- Every wrapped line will continue visually indented
vim.opt.breakindent = true

vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "split"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 20

-- Allow using gf to open .handler files from lib/*Stack files
vim.opt.path = vim.opt.path + "*"

vim.opt.includeexpr = "substitute(v:fname, '\\v\\.(handler|queueHandler)', '.ts', 'g')"

vim.diagnostic.config({
  virtual_text = false, -- Turn off inline diagnostics
})

---------------------
------ KEYMAPS ------
---------------------

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Previous/next mappings
vim.keymap.set("n", "<S-Tab>", "<cmd>bprev<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<C-p>", "<cmd>cprev<cr>", { desc = "Previous quickfix item" })
vim.keymap.set("n", "<C-n>", "<cmd>cnext<cr>", { desc = "Next quickfix item" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next [D]iagnostic message" })

-- Document existing key chains
local whichkeyGroups = {
  { "<leader>b", group = "[b]uffer" },
  { "<leader>bd", group = "[d]elete" },
  { "<leader>c", group = "[c]opy" },
  { "<leader>i", group = "[i]nsert" },
  { "<leader>g", group = "[g]it", mode = { "n", "v" } },
  { "<leader>gr", group = "[r]eset" },
  { "<leader>gs", group = "[s]tage" },
  { "<leader>gt", group = "[t]oggle" },
  { "<leader>l", group = "[l]sp" },
  { "<leader>lt", group = "[t]ype" },
  { "<leader>q", group = "[q]uickfix" },
  { "<leader>r", group = "[r]efactor" },
  { "<leader>s", group = "[s]earch" },
  { "<leader>t", group = "[t]mux / [t]oggle" },
}

local function leaderKeymap(desc, func)
  local keys = ""
  for value in string.gmatch(desc, "%[(.)%]") do
    keys = keys .. value
  end
  vim.keymap.set("n", "<Leader>" .. keys, func, { desc = desc })

  for i = 1, string.len(keys) - 1 do
    local value = string.sub(keys, 1, i)
    local whichKeyGroup = nil
    for _, group in ipairs(whichkeyGroups) do
      if group[1] == "<leader>" .. value then
        whichKeyGroup = group
        break
      end
    end
    if not whichKeyGroup then
      print("No which key group for " .. value .. " in " .. desc)
      print("Error in init.lua!")
    end
  end
end

-- Quickfix
leaderKeymap("[q]uickfix [d]iagnostics", vim.diagnostic.setqflist)

-- Terminal/Toggle
local functions = require("functions")
leaderKeymap("[t]mux [o]pen", functions.TmuxOpen)
leaderKeymap("[t]mux [r]epeat", functions.TmuxRepeat)
leaderKeymap("[t]oggle [t]est", functions.ToggleTest)
leaderKeymap("[t]oggle [h]tml", functions.ToggleHtml)

-- Search
leaderKeymap("[s]earch [i]nfrastructure", functions.SearchInfrastructure)

-- Insert
leaderKeymap("[i]nsert [g]uid", functions.InsertGuid)

-- Copy
leaderKeymap("[c]opy [p]ath", functions.CopyPath)

---------------------
--- AUTO COMMANDS ---
---------------------
local custom_group = vim.api.nvim_create_augroup("custom", { clear = true })

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = custom_group,
  pattern = "qf",
  callback = function()
    -- Do not show quickfix in buffer lists.
    vim.api.nvim_buf_set_option(0, "buflisted", false)

    -- Escape closes quickfix window.
    vim.keymap.set("n", "<ESC>", "<CMD>cclose<CR>", { buffer = true, remap = false, silent = true })

    -- `dd` deletes an item from the list.
    vim.keymap.set("n", "dd", DeleteQuickfixItems, { buffer = true })
    vim.keymap.set("x", "d", DeleteQuickfixItems, { buffer = true })
  end,
  desc = "Quickfix tweaks",
})

---------------------
------ PLUGINS ------
---------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    error("Error cloning lazy.nvim:\n" .. out)
  end
end
vim.opt.rtp:prepend(lazypath)

local plugins = {}

---@overload fun(opts: LazyPluginSpec)
local function plugin(opts)
  table.insert(plugins, opts)
end

plugin({
  "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically
})

plugin({ -- Useful plugin to show you pending keybinds.
  "folke/which-key.nvim",
  event = "VimEnter",
  config = function()
    require("which-key").setup({ icons = { group = "", mappings = false }, preset = "helix" })

    -- Document existing key chains
    require("which-key").add(whichkeyGroups)
  end,
})

plugin({ -- Adds git related signs to the gutter, as well as utilities for managing changes
  "lewis6991/gitsigns.nvim",
  opts = {
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map("n", "[g", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[g", bang = true })
        else
          gitsigns.nav_hunk("prev")
        end
      end, { desc = "previous [g]it change" })

      map("n", "]g", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]g", bang = true })
        else
          gitsigns.nav_hunk("next")
        end
      end, { desc = "next [g]it change" })

      map("n", "<leader>gsb", gitsigns.stage_buffer, { desc = "[b]uffer" })
      map("n", "<leader>gsh", gitsigns.stage_hunk, { desc = "[h]unk" })
      map("n", "<leader>grb", gitsigns.reset_buffer, { desc = "[b]uffer" })
      map("n", "<leader>grh", gitsigns.reset_hunk, { desc = "[h]unk" })
      map("n", "<leader>gu", gitsigns.undo_stage_hunk, { desc = "[u]ndo stage hunk" })
      map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "[p]review hunk" })
      map("n", "<leader>gb", gitsigns.blame_line, { desc = "[b]lame Line" })
      map("n", "<leader>gB", function()
        gitsigns.blame_line({ full = true })
      end, { desc = "[b]lame line (full)" })
      map("n", "<leader>gd", gitsigns.diffthis, { desc = "[d]iff against index" })
      map("n", "<leader>gD", function()
        gitsigns.diffthis("@")
      end, { desc = "[D]iff against last commit" })
      -- Toggles
      map("n", "<leader>gtb", gitsigns.toggle_current_line_blame, { desc = "[t]oggle [b]lame line" })
      map("n", "<leader>gtd", gitsigns.toggle_deleted, { desc = "[t]oggle [d]eleted" })
    end,
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
  },
})

plugin({
  "nvim-telescope/telescope.nvim",
  event = "VimEnter",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    { "nvim-telescope/telescope-ui-select.nvim" },
    { "nvim-tree/nvim-web-devicons" },
    {
      "axkirillov/easypick.nvim",
      requires = "nvim-telescope/telescope.nvim",
      opts = function(_, opts)
        local easypick = require("easypick")

        opts.pickers = {
          {
            name = "Last commit",
            command = "git diff --name-only HEAD HEAD~1 --relative",
            previewer = easypick.previewers.branch_diff({ base_branch = "HEAD~1" }),
          },
          {
            name = "Conflicts",
            command = "git diff --name-only --diff-filter=U --relative",
            previewer = easypick.previewers.file_diff(),
          },
        }
      end,
      keys = {
        { "<leader>se", "<cmd>:Easypick<cr>", desc = "[e]asypickers" },
      },
    },
    {
      "isak102/telescope-git-file-history.nvim",
      dependencies = { "tpope/vim-fugitive" },
    },
  },
  config = function()
    -- https://github.com/nvim-telescope/telescope.nvim/issues/3439
    -- Silence the specific position encoding message
    local notify_original = vim.notify
    vim.notify = function(msg, ...)
      if
        msg
        and (
          msg:match("position_encoding param is required")
          or msg:match("Defaulting to position encoding of the first client")
          or msg:match("multiple different client offset_encodings")
        )
      then
        return
      end
      return notify_original(msg, ...)
    end

    require("telescope").setup({
      defaults = {
        file_ignore_patterns = { ".git/.*", ".*.crt", "%.pem" },
        additional_args = { "--hidden" },
        hidden = true,
        path_display = { "filename_first" },
        layout_strategy = "vertical",
        layout_config = {
          width = 0.9,
          height = 0.9,
          preview_cutoff = 0,
        },
      },
      pickers = {
        find_files = {
          hidden = true,
        },
        grep_string = {
          additional_args = { "--hidden" },
        },
        live_grep = {
          additional_args = { "--hidden" },
        },
        buffers = {
          show_all_buffers = true,
          sort_mru = true,
          mappings = {
            i = {
              ["<c-d>"] = "delete_buffer",
            },
          },
        },
      },
      extensions = {
        ["ui-select"] = {
          require("telescope.themes").get_dropdown(),
        },
      },
    })

    pcall(require("telescope").load_extension, "fzf")
    pcall(require("telescope").load_extension, "ui-select")
    pcall(require("telescope").load_extension, "git_file_history")

    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[h]elp" })
    vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[k]eymaps" })
    vim.keymap.set("n", "<leader>sf", function()
      builtin.find_files()
    end, { desc = "[f]iles" })
    vim.keymap.set("n", "<leader>st", builtin.builtin, { desc = "[t]elescope" })
    vim.keymap.set("n", "<leader>sc", builtin.grep_string, { desc = "[c]urrent word" })
    vim.keymap.set("n", "<leader>sw", builtin.live_grep, { desc = "[w]ord" })
    vim.keymap.set("n", "<leader>sg", builtin.git_status, { desc = "[g]it status" })
    vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[d]iagnostics" })
    vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[r]esume" })
    vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = "recent files" })
    vim.keymap.set("n", "<leader>sb", builtin.buffers, { desc = "[b]uffers" })
    vim.keymap.set(
      "n",
      "<leader>gh",
      require("telescope").extensions.git_file_history.git_file_history,
      { desc = "[h]istory" }
    )
    vim.keymap.set("n", "<leader>/", function()
      builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown({
        winblend = 10,
        previewer = false,
      }))
    end, { desc = "fuzzily search in current buffer" })
    vim.keymap.set("n", "<leader>s/", function()
      builtin.live_grep({
        grep_open_files = true,
        prompt_title = "Live Grep in Open Files",
      })
    end, { desc = "[/] in open files" })
    vim.keymap.set("n", "<leader>sn", function()
      builtin.find_files({ cwd = vim.fn.stdpath("config") })
    end, { desc = "[n]eovim files" })
  end,
})

plugin({
  -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
  -- used for completion, annotations and signatures of Neovim apis
  "folke/lazydev.nvim",
  ft = "lua",
  opts = {
    library = {
      -- Load luvit types when the `vim.uv` word is found
      { path = "luvit-meta/library", words = { "vim%.uv" } },
    },
  },
})

plugin({ "Bilal2453/luvit-meta", lazy = true })

plugin({ -- Autocompletion
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    -- Snippet Engine & its associated nvim-cmp source
    {
      "L3MON4D3/LuaSnip",
      build = (function()
        -- Build Step is needed for regex support in snippets.
        -- This step is not supported in many windows environments.
        -- Remove the below condition to re-enable on windows.
        if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
          return
        end
        return "make install_jsregexp"
      end)(),
      dependencies = {
        -- `friendly-snippets` contains a variety of premade snippets.
        {
          "rafamadriz/friendly-snippets",
          config = function()
            require("luasnip.loaders.from_vscode").lazy_load()
          end,
        },
      },
    },
    "saadparwaiz1/cmp_luasnip",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-nvim-lsp-signature-help",

    {
      "zbirenbaum/copilot.lua",
      cmd = "Copilot",
      lazy = false,
      opts = {
        suggestion = { auto_trigger = true, debounce = 150 },
        copilot_node_command = COPILOT_NODE_PATH,
      },
    },
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local copilot = require("copilot.suggestion")

    local function has_words_before()
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end

    local mapping = {}
    mapping["<Tab>"] = cmp.mapping(function(fallback)
      if copilot.is_visible() then
        copilot.accept()
      elseif cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      elseif has_words_before() then
        cmp.complete()
      else
        fallback()
      end
    end, { "i", "s" })

    mapping["<C-x>"] = cmp.mapping(function()
      if copilot.is_visible() then
        copilot.next()
      end
    end)

    mapping["<C-z>"] = cmp.mapping(function()
      if copilot.is_visible() then
        copilot.prev()
      end
    end)

    mapping["<C-c>"] = cmp.mapping(function()
      if copilot.is_visible() then
        copilot.dismiss()
      end
    end)

    mapping["<CR>"] = cmp.mapping.confirm({ select = true })

    luasnip.config.setup({})

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = "menu,menuone,noinsert" },

      mapping = cmp.mapping.preset.insert(mapping),
      sources = {
        { name = "nvim_lsp" },
        { name = "luasnip" },
        { name = "path" },
        { name = "nvim_lsp_signature_help" },
      },
    })
  end,
})

plugin({
  "folke/tokyonight.nvim",
  priority = 1000, -- Make sure to load this before all the other start plugins.
  init = function()
    vim.cmd.colorscheme("tokyonight-night")
  end,
})

plugin({ -- Highlight todo, notes, etc in comments
  "folke/todo-comments.nvim",
  event = "VimEnter",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {},
})

plugin({ -- Collection of various small independent plugins/modules
  "echasnovski/mini.nvim",
  config = function()
    -- Better Around/Inside textobjects
    require("mini.ai").setup({ n_lines = 500 })

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    require("mini.surround").setup()

    require("mini.git").setup()

    -- Simple and easy statusline.
    local statusline = require("mini.statusline")
    statusline.setup({ use_icons = true })

    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return "%2l:%-2v"
    end
  end,
})

plugin({
  "alexghergh/nvim-tmux-navigation",
  keys = function()
    local p = require("nvim-tmux-navigation")
    return {
      { "<C-h>", p.NvimTmuxNavigateLeft, desc = "navigate [l]eft" },
      { "<C-j>", p.NvimTmuxNavigateDown, desc = "navigate [d]own" },
      { "<C-k>", p.NvimTmuxNavigateUp, desc = "navigate [u]p" },
      { "<C-l>", p.NvimTmuxNavigateRight, desc = "navigate [r]ight" },
    }
  end,
  opts = {
    disable_when_zoomed = true,
  },
})

plugin({
  "stevearc/oil.nvim",
  opts = {
    view_options = {
      show_hidden = true,
    },
  },
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "open oil" },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
})

plugin({ "coderifous/textobj-word-column.vim" })

plugin({
  "Asheq/close-buffers.vim",
  keys = {
    { "<leader>bdt", ":Bdelete this<CR>", desc = "[t]his" },
    { "<leader>bda", ":Bdelete all<CR>", desc = "[a]ll" },
    { "<leader>bdo", ":Bdelete other<CR>", desc = "[o]ther" },
  },
})

plugin({
  "yutkat/git-rebase-auto-diff.nvim",
  ft = { "gitrebase" },
  opts = {},
})

plugin({
  "pmizio/typescript-tools.nvim",
  dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  opts = {
    settings = {
      expose_as_code_action = "all",
    },
  },
})

plugin({ --unique f/F indicators for each word on the line
  "jinh0/eyeliner.nvim",
  keys = { "t", "f", "T", "F" },
  opts = {
    highlight_on_key = true,
    dim = true,
  },
})

plugin({
  -- Add indentation guides even on blank lines
  "lukas-reineke/indent-blankline.nvim",
  main = "ibl",
  opts = {},
})

plugin({ "almo7aya/openingh.nvim" })

---------------------
----- LANGUAGES -----
---------------------

local languages = {
  angular = {
    mason = {
      ["angular-language-server"] = {},
    },
  },
  astro = {
    mason = {
      ["astro-language-server"] = {},
    },
    conform = { "prettierd" },
  },

  css = {
    mason = {
      ["css-lsp"] = {},
    },
    conform = { "prettierd" },
  },

  diff = {},
  htmlangular = {
    conform = { "prettierd" },
  },
  html = {},
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
    conform = { "elm_format" },
  },

  gleam = {
    conform = { "gleam" },
    -- don't install using mason as it is included in gleam itself (installed via brew)
    lspconfig = { gleam = {} },
  },

  javascript = {
    mason = {
      ["js-debug-adapter"] = {},
    },
    conform = {
      "prettierd",
    },
  },

  json = {
    conform = { "prettierd" },
  },

  jsonc = {
    conform = { "prettierd" },
  },

  typescript = {
    mason = {
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
    conform = { "prettierd" },
  },

  lua = {
    mason = {
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = "Replace",
            },
          },
        },
      },
    },
    conform = {
      "stylua",
    },
  },

  ruby = {
    -- don't install using mason, instead include it in the repo
    lspconfig = {
      rubocop = {
        cmd = { "rubocop", "--lsp" },
        filetypes = { "ruby" },
        root_markers = { "Gemfile", ".git" },
      },
    },
    conform = {
      "rubocop",
    },
  },

  rust = {
    mason = {
      rust_analyzer = {
        settings = {
          ["rust-analyzer"] = {
            check = {
              command = "clippy",
            },
          },
        },
      },
    },
    conform = {
      "rustfmt",
    },
  },

  sh = {
    mason = {
      shellcheck = {},
      ["bash-language-server"] = {},
    },
    conform = { "shfmt" },
    treesitter = "bash",
  },

  sql = {
    mason = {
      sqlfmt = {},
      sqlls = {},
    },
  },
}

local treesitter_installs = {}
for _, config in pairs(languages) do
  if config.treesitter then
    table.insert(treesitter_installs, config.treesitter)
  else
    table.insert(treesitter_installs, config.treesitter)
  end
end

local mason_servers = {}
for _, config in pairs(languages) do
  if config.mason then
    for server, opts in pairs(config.mason) do
      mason_servers[server] = opts
    end
  end
end

local lsp_servers = {}
for _, config in pairs(languages) do
  if config.lspconfig then
    for server, opts in pairs(config.lspconfig) do
      lsp_servers[server] = opts
    end
  end
end

local formatters_by_ft = {}
for lang, config in pairs(languages) do
  if config.conform then
    formatters_by_ft[lang] = config.conform
  end
end

if DEBUG then
  print("Treesitter installs: " .. vim.inspect(treesitter_installs))
  print("Mason servers: " .. vim.inspect(mason_servers))
  print("LSP servers: " .. vim.inspect(lsp_servers))
  print("Formatters by filetype: " .. vim.inspect(formatters_by_ft))
end

plugin({
  -- Main LSP Configuration
  "neovim/nvim-lspconfig",
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    { "williamboman/mason.nvim", config = true }, -- Must be loaded before dependants
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",

    -- Useful status updates for LSP.
    { "j-hui/fidget.nvim", opts = {} },

    -- Allows extra capabilities provided by nvim-cmp
    "hrsh7th/nvim-cmp",
    "hrsh7th/cmp-nvim-lsp",
  },
  config = function()
    for server, opts in pairs(lsp_servers) do
      require("lspconfig")[server].setup(opts)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or "n"
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
        end

        map("<leader>ld", require("telescope.builtin").lsp_definitions, "[L]sp [d]efinition")
        map("<leader>lD", vim.lsp.buf.declaration, "[L]sp [D]eclaration")

        map("<leader>lR", function()
          require("telescope.builtin").lsp_references({ show_line = false })
        end, "[L]sp [R]eferences")

        map("<leader>lI", require("telescope.builtin").lsp_implementations, "[L]sp [I]mplementation")

        map("<leader>lt", require("telescope.builtin").lsp_type_definitions, "[L]sp [t]ype definition")

        map("<leader>lr", vim.lsp.buf.rename, "[L]sp [r]ename")

        map("<leader>la", vim.lsp.buf.code_action, "[L]sp code [a]ction")
        map("<leader>la", vim.lsp.buf.code_action, "[L]sp code [a]ction", "v")

        -- Highlight references of the word under your cursor
        -- when your cursor rests there for a little while.
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
          local highlight_augroup = vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd("LspDetach", {
            group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
            end,
          })
        end
      end,
    })

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

    require("mason").setup()

    require("mason-tool-installer").setup({ ensure_installed = vim.tbl_keys(mason_servers) })

    require("mason-lspconfig").setup({
      handlers = {
        function(server_name)
          local server = mason_servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for tsserver)
          server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
          require("lspconfig")[server_name].setup(server)
        end,
      },
    })
  end,
})

plugin({ -- Highlight, edit, and navigate code
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  opts = {
    ensure_installed = treesitter_installs,
    auto_install = true,
    highlight = {
      enable = true,
    },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        node_incremental = "v",
        node_decremental = "V",
      },
    },
    textobjects = {
      select = {
        enable = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
        },
        selection_modes = {
          ["@function.outer"] = "V", -- linewise
        },
      },
      swap = {
        enable = true,
        swap_next = {
          ["<leader>ls"] = "@parameter.inner",
        },
        swap_previous = {
          ["<leader>lS"] = "@parameter.inner",
        },
      },
      move = {
        enable = true,
        set_jumps = true, -- whether to set jumps in the jumplist
        goto_next_start = {
          ["]m"] = "@function.inner",
        },
        goto_next_end = {
          ["]M"] = "@function.outer",
        },
        goto_previous_start = {
          ["[m"] = "@function.inner",
        },
        goto_previous_end = {
          ["[M"] = "@function.outer",
        },
      },
    },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter-context",
    "nvim-treesitter/nvim-treesitter-textobjects",
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
})

plugin({ -- Autoformat
  "stevearc/conform.nvim",
  lazy = false,
  keys = {
    {
      "<leader>lf",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = "",
      desc = "[f]ormat buffer",
    },
  },
  opts = {
    notify_on_error = false,
    format_on_save = true,
    formatters_by_ft = formatters_by_ft,
  },
})

plugin({
  "ThePrimeagen/refactoring.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  lazy = false,
  opts = {
    printf_statements = {
      ts = {
        'console.log("debug path a %s");',
      },
    },
  },
  config = function()
    leaderKeymap("[r]efactor print [v]ariable", function()
      require("refactoring").debug.print_var({})
    end)

    leaderKeymap("[r]efactor [p]rintf", function()
      require("refactoring").debug.printf({})
    end)

    leaderKeymap("[r]efactor [c]leanup", function()
      require("refactoring").debug.cleanup({})
    end)
  end,
  --   printf_statements = {
  --     -- add a custom printf statement for cpp
  --     ts = {
  --       'console.log("debug path %s");',
  --     },
  --   },
  --   print_var_statements = {
  --     -- add a custom print_var statement for cpp
  --     ts = {
  --       'console.log("custom print var %s %%s", %s);',
  --     },
  --   },
  -- },
})

require("lazy").setup(plugins)
