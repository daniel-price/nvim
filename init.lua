local languages = require("languages")

---------------------
----- CONSTANTS -----
---------------------

local DEBUG = false
-- Path to Node.js executable managed by Mise for GitHub Copilot so that it works even in projects with different Node versions
local COPILOT_NODE_PATH = vim.fn.expand("$HOME") .. "/.local/share/mise/installs/node/24.10.0/bin/node"

---------------------
------ FUNCTIONS ----
---------------------

local function debugPrint(...)
  if DEBUG then
    for _, value in ipairs({ ... }) do
      if type(value) == "table" then
        value = vim.inspect(value)
      end
      print(value)
    end
  end
end

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
  jump = { float = true }, -- Show diagnostics in a floating window when jumping between them
})

---------------------
------ KEYMAPS ------
---------------------

-- Clear highlights on search when pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Previous/next mappings
vim.keymap.set("n", "<S-Tab>", "<cmd>bprev<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })

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
  { "<leader>n", group = "[n]eovim" },
  { "<leader>lt", group = "[t]ype" },
  { "<leader>q", group = "[q]uickfix" },
  { "<leader>r", group = "[r]efactor" },
  { "<leader>s", group = "[s]earch" },
  { "<leader>t", group = "[t]oggle" },
  { "<leader>u", group = "[u]ndo" },
  { "<leader>z", group = "[z]ellij" },
}

local function parseLeaderKeys(desc, who)
  local keys = ""
  for value in string.gmatch(desc, "%[(.)%]") do
    keys = keys .. value
  end
  if keys == "" then
    error((who or "keymap") .. ": no [x] keys found in desc: " .. desc)
  end
  return keys
end

local function validateWhichKeyPrefixes(desc, keys)
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
      print("ERROR: No which key group for " .. value .. " in " .. desc .. ". Add to whichkeyGroups.")
    end
  end
end

local function leaderKeymap(desc, func, modes)
  modes = modes or { "n" } -- Default to normal mode if not specified
  -- Convert single mode to array for consistent handling
  if type(modes) == "string" then
    modes = { modes }
  end

  local keys = parseLeaderKeys(desc, "leaderKeymap")

  -- Set keymap for each mode
  for _, mode in ipairs(modes) do
    vim.keymap.set(mode, "<Leader>" .. keys, func, { desc = desc })
  end

  validateWhichKeyPrefixes(desc, keys)
end

-- Helper to generate Lazy.nvim `keys = { ... }` entries using the same
-- `[x]`-style descriptions as `leaderKeymap`, but without eagerly requiring
-- plugin modules.
--
-- Usage examples:
--   keys = {
--     lazyLeaderKeymap("[s]earch [h]elp", function()
--       require("fzf-lua").help_tags()
--     end),
--     lazyLeaderKeymap("[u]ndo [t]ree", "<cmd>UndotreeToggle<cr>"),
--   }
local function lazyLeaderKeymap(desc, rhs, opts)
  opts = opts or {}

  local keys = parseLeaderKeys(desc, "lazyLeaderKeymap")
  validateWhichKeyPrefixes(desc, keys)

  local o = vim.tbl_extend("force", {}, opts)
  o.desc = o.desc or desc
  o.mode = o.mode or "n"
  return vim.tbl_extend("force", { "<leader>" .. keys, rhs }, o)
end

-- Quickfix
leaderKeymap("[q]uickfix [d]iagnostics", vim.diagnostic.setqflist)
leaderKeymap("[q]uickfix [p]revious", "<cmd>cprev<cr>")
leaderKeymap("[q]uickfix [n]ext", "<cmd>cnext<cr>")

-- Terminal/Toggle
local functions = require("functions")
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
    vim.api.nvim_set_option_value("buflisted", false, { buf = 0 })

    -- Escape closes quickfix window.
    vim.keymap.set("n", "<ESC>", "<CMD>cclose<CR>", { buffer = true, remap = false, silent = true })

    -- `dd` deletes an item from the list.
    vim.keymap.set("n", "dd", functions.DeleteQuickfixItems, { buffer = true })
    vim.keymap.set("x", "d", functions.DeleteQuickfixItems, { buffer = true })
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

      ---Wrap gitsigns functions to avoid type issue from lua-language-server
      ---@type fun(direction: 'next'|'prev')
      local nav_hunk = gitsigns.nav_hunk

      ---@type fun(base: '@')
      local diffthis = gitsigns.diffthis

      nav_hunk("prev")

      -- Navigation
      map("n", "[g", function()
        if vim.wo.diff then
          vim.cmd.normal({ "[g", bang = true })
        else
          nav_hunk("prev")
        end
      end, { desc = "previous [g]it change" })

      map("n", "]g", function()
        if vim.wo.diff then
          vim.cmd.normal({ "]g", bang = true })
        else
          nav_hunk("next")
        end
      end, { desc = "next [g]it change" })

      map("n", "<leader>gsb", gitsigns.stage_buffer, { desc = "[b]uffer" })
      map("n", "<leader>gsh", gitsigns.stage_hunk, { desc = "[h]unk" })
      map("n", "<leader>grb", gitsigns.reset_buffer, { desc = "[b]uffer" })
      map("n", "<leader>grh", gitsigns.reset_hunk, { desc = "[h]unk" })
      map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "[p]review hunk" })
      map("n", "<leader>gb", gitsigns.blame_line, { desc = "[b]lame Line" })
      map("n", "<leader>gB", function()
        gitsigns.blame_line({ full = true })
      end, { desc = "[b]lame line (full)" })
      map("n", "<leader>gd", diffthis, { desc = "[d]iff against index" })
      map("n", "<leader>gD", function()
        diffthis("@")
      end, { desc = "[D]iff against last commit" })
      -- Toggles
      map("n", "<leader>gtb", gitsigns.toggle_current_line_blame, { desc = "[t]oggle [b]lame line" })
      map("n", "<leader>gtd", gitsigns.preview_hunk_inline, { desc = "[t]oggle [d]eleted" })
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
  "ibhagwan/fzf-lua",
  event = "VimEnter",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  keys = {
    {
      "<leader>sh",
      function()
        require("fzf-lua").help_tags()
      end,
      desc = "[h]elp",
    },
    {
      "<leader>sk",
      function()
        require("fzf-lua").keymaps()
      end,
      desc = "[k]eymaps",
    },
    {
      "<leader>sp",
      function()
        require("fzf-lua").builtin()
      end,
      desc = "[p]ickers",
    },
    {
      "<leader>sc",
      function()
        require("fzf-lua").grep_cword()
      end,
      desc = "[c]urrent word",
    },
    {
      "<leader>sw",
      function()
        require("fzf-lua").live_grep()
      end,
      desc = "[w]ord",
    },
    {
      "<leader>sg",
      function()
        require("fzf-lua").git_status()
      end,
      desc = "[g]it status",
    },
    {
      "<leader>sd",
      function()
        require("fzf-lua").diagnostics_workspace()
      end,
      desc = "[d]iagnostics",
    },
    {
      "<leader>sr",
      function()
        require("fzf-lua").resume()
      end,
      desc = "[r]esume",
    },
    {
      "<leader>s.",
      function()
        require("fzf-lua").oldfiles()
      end,
      desc = "recent files",
    },
    {
      "<leader>sb",
      function()
        require("fzf-lua").buffers()
      end,
      desc = "[b]uffers",
    },
    {
      "<leader>/",
      function()
        require("fzf-lua").blines({ fzf_opts = { ["--layout"] = "reverse-list" }, previewer = false })
      end,
      desc = "fuzzy search current buffer",
    },
    {
      "<leader>s/",
      function()
        require("fzf-lua").live_grep({ rg_opts = "--no-heading --with-filename --line-number --column --smart-case" })
      end,
      desc = "[/] in open files",
    },
    {
      "<leader>sn",
      function()
        require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
      end,
      desc = "[n]eovim files",
    },
    {
      "<leader>sf",
      function()
        require("fzf-lua").files({ hidden = true })
      end,
      desc = "[s]earch [f]iles",
    },
    {
      "<leader>se",
      function()
        require("fzf-lua").files({
          cmd = "git diff --name-only HEAD HEAD~1 --relative",
          previewer = "git_diff",
        })
      end,
      desc = "[e]asypickers (last commit)",
    },
  },
  config = function()
    local fzf = require("fzf-lua")

    fzf.setup({
      "telescope",
      winopts = {
        height = 1,
        width = 1,
        preview = {
          layout = "vertical",
          vertical = "up:60%", -- similar to telescope vertical layout
        },
      },
    })

    -- Optional: simulate your easypick.nvim pickers with custom commands
    vim.api.nvim_create_user_command("FzfLastCommit", function()
      fzf.files({
        cmd = "git diff --name-only HEAD HEAD~1 --relative",
        previewer = "git_diff",
      })
    end, {})
    vim.api.nvim_create_user_command("FzfConflicts", function()
      fzf.files({
        cmd = "git diff --name-only --diff-filter=U --relative",
        previewer = "git_diff",
      })
    end, {})
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
  lazy = false,
  priority = 1000, -- Make sure to load this before all the other start plugins.
  init = function()
    vim.cmd.colorscheme("tokyonight")

    local theme = vim.fn.system("defaults read -g AppleInterfaceStyle"):gsub("\n", "")

    if theme == "Dark" then
      vim.o.background = "dark"
    else
      vim.o.background = "light"
    end
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

local treesitter_installs = languages.treesitter_installs
local mason_servers = languages.mason_tools
local lsp_servers = languages.lsp_servers
local formatters_by_ft = languages.formatters_by_ft
local formatters = languages.formatters

debugPrint("Treesitter installs: ", vim.inspect(treesitter_installs))
debugPrint("Mason servers/tools: ", vim.inspect(mason_servers))
debugPrint("LSP servers: ", vim.inspect(lsp_servers))
debugPrint("Formatters by filetype: ", vim.inspect(formatters_by_ft))
debugPrint("Formatters: ", vim.inspect(formatters))

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
      vim.lsp.config(server, opts)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or "n"
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = desc })
        end

        local fzf = require("fzf-lua")

        map("<leader>ld", fzf.lsp_definitions, "[L]sp [d]efinition")
        map("<leader>lD", vim.lsp.buf.declaration, "[L]sp [D]eclaration")

        map("<leader>lR", function()
          fzf.lsp_references({ show_line = false })
        end, "[L]sp [R]eferences")

        map("<leader>lI", fzf.lsp_implementations, "[L]sp [I]mplementation")

        map("<leader>lt", fzf.lsp_typedefs, "[L]sp [t]ype definition")

        map("<leader>lr", vim.lsp.buf.rename, "[L]sp [r]ename")

        -- Highlight references of the word under your cursor
        -- when your cursor rests there for a little while.

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
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

    require("mason-tool-installer").setup({
      ensure_installed = vim.tbl_keys(mason_servers),
    })

    require("mason-lspconfig").setup({
      handlers = {
        function(server_name)
          local server = mason_servers[server_name] or {}
          -- This handles overriding only values explicitly passed
          -- by the server configuration above. Useful when disabling
          -- certain features of an LSP (for example, turning off formatting for tsserver)
          server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
          vim.lsp.config(server)
        end,
      },
      automatic_enable = {
        exclude = { "harper_ls" },
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
    formatters = formatters,
    log_level = vim.log.levels.DEBUG,
  },
})

plugin({
  "ThePrimeagen/refactoring.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  lazy = false,
  keys = {
    {
      "<leader>rv",
      function()
        require("refactoring").debug.print_var({})
      end,
      desc = "[r]efactor print [v]ariable",
    },
    {
      "<leader>rp",
      function()
        require("refactoring").debug.printf({})
      end,
      desc = "[r]efactor [p]rintf",
    },
    {
      "<leader>rc",
      function()
        require("refactoring").debug.cleanup({})
      end,
      desc = "[r]efactor [c]leanup",
    },
  },
  opts = {
    printf_statements = {
      ts = {
        'console.log("debug path a %s");',
      },
    },
  },
  config = function(_, opts)
    require("refactoring").setup(opts)
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

plugin({
  "rachartier/tiny-code-action.nvim",
  dependencies = {
    { "nvim-lua/plenary.nvim" },

    -- optional picker via telescope
    { "nvim-telescope/telescope.nvim" },
  },
  event = "LspAttach",
  keys = {
    {
      "<leader>la",
      function()
        require("tiny-code-action").code_action({})
      end,
      desc = "[l]sp code [a]ction",
    },
  },
  opts = {
    backend = "delta",
    picker = "select",
  },
})

plugin({
  "mbbill/undotree",
  keys = {
    { "<leader>ut", "<cmd>UndotreeToggle<cr>", desc = "[u]ndo [t]ree" },
  },
})

plugin({
  "folke/sidekick.nvim",
  opts = {
    -- add any options here
    cli = {
      mux = {
        backend = "zellij",
        enabled = true,
      },
    },
  },
  keys = {
    {
      "<tab>",
      function()
        -- if there is a next edit, jump to it, otherwise apply it if any
        if not require("sidekick").nes_jump_or_apply() then
          return "<Tab>" -- fallback to normal tab
        end
      end,
      expr = true,
      desc = "Goto/Apply Next Edit Suggestion",
      -- insert mode only
      mode = "i",
    },
    {
      "<C-.>",
      function()
        --open or focus the sidekick cursor CLI
        if vim.fn.bufwinnr("Sidekick - Cursor") ~= -1 then
          require("sidekick").focus("cursor")
          return
        end
        require("sidekick.cli").toggle({ name = "cursor", focus = true })
      end,
      desc = "Sidekick Toggle Cursor",
    },
    {
      "<leader>as",
      function()
        require("sidekick.cli").select()
      end,
      -- Or to select only installed tools:
      -- require("sidekick.cli").select({ filter = { installed = true } })
      desc = "Select CLI",
    },
    {
      "<leader>ad",
      function()
        require("sidekick.cli").close()
      end,
      desc = "Detach a CLI Session",
    },
    {
      "<leader>at",
      function()
        require("sidekick.cli").send({ msg = "{this}" })
      end,
      mode = { "x", "n" },
      desc = "Send This",
    },
    {
      "<leader>af",
      function()
        require("sidekick.cli").send({ msg = "{file}" })
      end,
      desc = "Send File",
    },
    {
      "<leader>av",
      function()
        require("sidekick.cli").send({ msg = "{selection}" })
      end,
      mode = { "x" },
      desc = "Send Visual Selection",
    },
    {
      "<leader>ap",
      function()
        require("sidekick.cli").prompt()
      end,
      mode = { "n", "x" },
      desc = "Sidekick Select Prompt",
    },
  },
})

plugin({
  "swaits/zellij-nav.nvim",
  lazy = true,
  event = "VeryLazy",
  keys = {
    {
      "<c-h>",
      function()
        require("zellij-nav").left()
      end,
      { silent = true, desc = "navigate left or tab" },
    },
    {
      "<c-j>",
      function()
        require("zellij-nav").down()
      end,
      { silent = true, desc = "navigate down" },
    },
    {
      "<c-k>",
      function()
        require("zellij-nav").up()
      end,
      { silent = true, desc = "navigate up" },
    },
    {
      "<c-l>",
      function()
        require("zellij-nav").right()
      end,
      { silent = true, desc = "navigate right or tab" },
    },
  },
  opts = {},
})

leaderKeymap("[z]ellij [o]pen", functions.OpenZellijPane)
leaderKeymap("[z]ellij [r]epeat", functions.ZellijRepeat)

leaderKeymap("[n]eovim [u]pdate", functions.NeovimUpdate)

require("lazy").setup(plugins)
