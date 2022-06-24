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

local function ToggleTest()
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

local function ToggleHtml()
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
  local paneId = stripWhitespace(vim.fn.system('tmux display -p -t "~" "#D"'))
  if paneId == nil or paneId == "" then
    local newPaneId = stripWhitespace(vim.fn.system('tmux split-window -d -h -P -F "#{pane_id}"'))

    vim.fn.system("tmux select-pane -m -t " .. newPaneId)
    return newPaneId
  end
  return paneId
end

local function runInPane(cmd)
  local paneId = getMarkedPaneId()

  vim.fn.system(
    "(tmux send-keys -t " .. paneId .. " -X cancel || true) && tmux send-keys -t " .. paneId .. ' "' .. cmd .. '" Enter'
  )
end

local function TmuxOpen()
  runInPane("")
end

local function TmuxRepeat()
  runInPane("Up")
end

local function SearchInfrastructure()
  local bufferPath = getBufferName()

  local searchString = string.match(bufferPath, ".*(src.*).ts")
  if not searchString then
    print("no search string found")
    return
  end
  require("telescope.builtin").grep_string({ search = searchString .. ".handler" })
end

local function InsertGuid()
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

local function CopyPath()
  local filepath = vim.fn.expand("%")
  vim.fn.setreg("+", filepath)
end

return {
  ToggleTest = ToggleTest,
  ToggleHtml = ToggleHtml,
  TmuxOpen = TmuxOpen,
  TmuxRepeat = TmuxRepeat,
  SearchInfrastructure = SearchInfrastructure,
  InsertGuid = InsertGuid,
  CopyPath = CopyPath,
}
