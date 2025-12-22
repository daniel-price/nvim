local M = {}

local function pathIsElmFile(path)
  return string.match(path, ".*%.elm")
end

local function pathIsElmTestFile(path)
  return string.match(path, ".*/tests/.*Test%.elm")
end

local function pathIsTypescriptFile(path)
  return string.match(path, ".*%.ts")
end

local function pathIsTypescriptTestFile(path)
  return string.match(path, ".*%.spec%.ts")
end

local function fileExists(name)
  local f = io.open(name, "r")
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

local function getBufferName()
  local bufferPath = vim.api.nvim_buf_get_name(0)
  return string.gsub(bufferPath, "%s+", "")
end

M.ToggleTest = function()
  local bufferPath = getBufferName()

  if pathIsTypescriptFile(bufferPath) then
    if pathIsTypescriptTestFile(bufferPath) then
      local implementationFile = string.gsub(bufferPath, "%.spec%.ts", ".ts")
      if fileExists(implementationFile) then
        vim.api.nvim_command("edit " .. implementationFile)
      else
        print("No implementation file found (" .. implementationFile .. ")")
      end

      return
    end

    local testFile = string.gsub(bufferPath, "%.ts", ".spec.ts")
    if testFile then
      vim.api.nvim_command("edit " .. testFile)
    end
    return
  end

  if pathIsElmFile(bufferPath) then
    if pathIsElmTestFile(bufferPath) then
      local implementationFile = string.gsub(bufferPath, "/tests/", "/src/")
      implementationFile = string.gsub(implementationFile, "Test.elm", ".elm")
      if fileExists(implementationFile) then
        vim.api.nvim_command("edit " .. implementationFile)
      else
        print("No implementation file found (" .. implementationFile .. ")")
      end

      return
    end

    local testFile = string.gsub(bufferPath, "/src/", "/tests/")
    testFile = string.gsub(testFile, "%.elm", "Test.elm")
    if testFile then
      vim.api.nvim_command("edit " .. testFile)
    end
  end

  print("Unknown file type")
end

M.ToggleHtml = function()
  local bufferPath = getBufferName()
  local isHtmlFile = string.match(bufferPath, ".*%.component%.html")
  if isHtmlFile then
    local implementationFile = string.gsub(bufferPath, "%.component%.html", ".component.ts")
    if fileExists(implementationFile) then
      vim.api.nvim_command("edit " .. implementationFile)
    else
      print("No implementation file found (" .. implementationFile .. ")")
    end

    return
  else
    local htmlFile = string.gsub(bufferPath, "%.component%.ts", ".component.html")
    if fileExists(htmlFile) then
      vim.api.nvim_command("edit " .. htmlFile)
    else
      print("No html file found (" .. htmlFile .. ")")
    end

    return
  end
end

local function stripWhitespace(str)
  return string.gsub(str, "%s+", "")
end

local function getMarkedPaneId()
  local paneId = stripWhitespace(vim.fn.system('zellij list-sessions --format json | jq -r ".[0].name"'))
  if paneId == nil or paneId == "" then
    local newPaneId = stripWhitespace(vim.fn.system('zellij new-session --name "neovim" --print-session-name'))

    vim.fn.system("zellij attach " .. newPaneId)
    return newPaneId
  end
  return paneId
end

local function runInPane(cmd)
  local paneId = getMarkedPaneId()

  print("Running in pane: " .. paneId .. " command: " .. cmd)

  vim.fn.system("zellij send --session " .. paneId .. " -- " .. cmd)
end

M.ZellijOpen = function()
  runInPane("")
end

M.ZellijRepeat = function()
  runInPane("Up")
end

M.SearchInfrastructure = function()
  local bufferPath = getBufferName()

  local searchString = string.match(bufferPath, ".*(src.*).ts")
  if not searchString then
    print("no search string found")
    return
  end
  require("fzf-lua").grep({ search = searchString .. ".handler" })
end

M.InsertGuid = function()
  local template = "xxxxxxxx"
  local guid = string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format("%x", v)
  end)

  local pos = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()

  local next_char = line:sub(pos + 2, pos + 2)

  local insertAtIndex = pos
  if next_char == "'" or next_char == '"' then
    insertAtIndex = pos + 1
  end

  local nline = line:sub(0, insertAtIndex) .. guid .. line:sub(insertAtIndex + 1)
  vim.api.nvim_set_current_line(nline)
end

M.CopyPath = function()
  local filepath = vim.fn.expand("%")
  vim.fn.setreg("+", filepath)
end

M.DeleteQuickfixItems = function()
  local mode = vim.api.nvim_get_mode()["mode"]

  local start_idx
  local count

  if mode == "n" then
    -- Normal mode
    start_idx = vim.fn.line(".")
    count = vim.v.count > 0 and vim.v.count or 1
  else
    -- Visual mode
    local v_start_idx = vim.fn.line("v")
    local v_end_idx = vim.fn.line(".")

    start_idx = math.min(v_start_idx, v_end_idx)
    count = math.abs(v_end_idx - v_start_idx) + 1

    -- Go back to normal
    vim.api.nvim_feedkeys(
      vim.api.nvim_replace_termcodes(
        "<esc>", -- what to escape
        true, -- Vim leftovers
        false, -- Also replace `<lt>`?
        true -- Replace keycodes (like `<esc>`)?
      ),
      "x", -- Mode flag
      false -- Should be false, since we already `nvim_replace_termcodes()`
    )
  end

  local qflist = vim.fn.getqflist()

  for _ = 1, count, 1 do
    table.remove(qflist, start_idx)
  end

  vim.fn.setqflist(qflist, "r")
  vim.fn.cursor(start_idx, 1)
end

M.OpenZellijPane = function()
  --print vim.env table
  print(vim.inspect(vim.env))
  vim.fn.system("zellij action new-pane --direction Right && zellij action focus-previous-pane")
end

M.NeovimUpdate = function()
  vim.api.nvim_command("MasonUpdate")
  vim.api.nvim_command("Lazy update")
  vim.api.nvim_command("TSUpdate")
end

return M
