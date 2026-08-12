vim.pack.add { 'https://github.com/hat0uma/csvview.nvim' }

require('csvview').setup {
  view = {
    display_mode = 'border',
  },
}

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Display CSV and TSV files as aligned tables',
  group = vim.api.nvim_create_augroup('data-files-csv-view', { clear = true }),
  pattern = { 'csv', 'tsv' },
  callback = function() vim.cmd 'CsvViewEnable' end,
})

vim.keymap.set('n', '<leader>tc', '<cmd>CsvViewToggle<cr>', { desc = '[T]oggle [C]SV table view' })
