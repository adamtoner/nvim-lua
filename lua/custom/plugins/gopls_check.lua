local function gopls_check_files(files, title)
  if vim.fn.executable 'gopls' ~= 1 then
    vim.notify('gopls is not on PATH', vim.log.levels.ERROR)
    return
  end

  if #files == 0 then
    vim.notify('No Go files to check', vim.log.levels.WARN)
    return
  end

  local cmd = vim.list_extend({ 'gopls', 'check' }, files)
  vim.notify(('Running gopls check for %d files in %s'):format(#files, title), vim.log.levels.INFO)

  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      local output = vim.split((result.stdout or '') .. (result.stderr or ''), '\n', { trimempty = true })
      local items = {}

      for _, line in ipairs(output) do
        local filename, lnum, col, text = line:match '^(.-):(%d+):(%d+):%s*(.*)$'
        if filename then
          table.insert(items, {
            filename = filename,
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = text,
          })
        end
      end

      if #items == 0 then
        vim.fn.setqflist({}, 'r', { title = 'gopls check', lines = output })
        if result.code == 0 then
          vim.notify('gopls check passed', vim.log.levels.INFO)
        else
          vim.cmd 'copen'
        end
        return
      end

      vim.fn.setqflist({}, 'r', { title = 'gopls check', items = items })
      vim.cmd 'copen'
    end)
  end)
end

local function go_files_under(dir)
  return vim.tbl_filter(function(file) return not file:match '/%.git/' and not file:match '/vendor/' end, vim.fn.globpath(dir, '**/*.go', false, true))
end

local function gopls_check(dir)
  local files = go_files_under(dir)
  if #files == 0 then
    vim.notify('No Go files in ' .. dir, vim.log.levels.WARN)
    return
  end

  gopls_check_files(files, dir)
end

local function maybe_write_current_file()
  if vim.bo.buftype == '' and vim.bo.modified then vim.cmd 'write' end
end

local function oil_current_dir()
  if vim.bo.filetype ~= 'oil' then return nil end

  local ok, oil = pcall(require, 'oil')
  if not ok then return nil end

  local dir_ok, dir = pcall(oil.get_current_dir, 0)
  if dir_ok and dir then return dir end

  dir_ok, dir = pcall(oil.get_current_dir)
  if dir_ok and dir then return dir end

  return nil
end

local function current_dir()
  local oil_dir = oil_current_dir()
  if oil_dir then return oil_dir end

  local name = vim.api.nvim_buf_get_name(0)
  if name == '' then return vim.fn.getcwd() end
  if vim.fn.isdirectory(name) == 1 then return name end

  return vim.fs.dirname(name)
end

local function repo_root()
  local dir = current_dir()
  local root = vim.fs.root(dir, { 'go.work', 'go.mod', '.git' })
  return root or dir
end

local function gopls_check_current_dir()
  maybe_write_current_file()
  gopls_check(current_dir())
end

local function gopls_check_repo_root()
  maybe_write_current_file()
  gopls_check(repo_root())
end

local function diagnostic_error_files_under(dir)
  local files = {}
  local seen = {}
  local prefix = vim.fs.normalize(dir .. '/')

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    local normalized = name ~= '' and vim.fs.normalize(name) or ''
    if
      normalized:sub(-3) == '.go'
      and normalized:sub(1, #prefix) == prefix
      and #vim.diagnostic.get(bufnr, { severity = vim.diagnostic.severity.ERROR }) > 0
      and not seen[normalized]
    then
      table.insert(files, normalized)
      seen[normalized] = true
    end
  end

  return files
end

local function gopls_check_current_dir_diagnostics()
  maybe_write_current_file()
  local dir = current_dir()
  gopls_check_files(diagnostic_error_files_under(dir), dir .. ' diagnostic errors')
end

local function gopls_check_repo_root_diagnostics()
  maybe_write_current_file()
  local root = repo_root()
  gopls_check_files(diagnostic_error_files_under(root), root .. ' diagnostic errors')
end

local ok, which_key = pcall(require, 'which-key')
if ok then which_key.add { { '<leader>g', group = '[G]o' } } end

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'go', 'oil' },
  callback = function(event)
    vim.keymap.set('n', '<leader>gc', gopls_check_current_dir, {
      buffer = event.buf,
      desc = 'gopls check current directory recursively',
    })

    vim.keymap.set('n', '<leader>gC', gopls_check_repo_root, {
      buffer = event.buf,
      desc = 'gopls check repo root recursively',
    })

    vim.keymap.set('n', '<leader>gd', gopls_check_current_dir_diagnostics, {
      buffer = event.buf,
      desc = 'gopls check files with diagnostic errors in current directory recursively',
    })

    vim.keymap.set('n', '<leader>gD', gopls_check_repo_root_diagnostics, {
      buffer = event.buf,
      desc = 'gopls check files with diagnostic errors in repo root recursively',
    })
  end,
})
