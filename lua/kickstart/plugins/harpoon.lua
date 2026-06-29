vim.pack.add {
  { src = 'https://github.com/ThePrimeagen/harpoon', version = 'harpoon2' },
  'https://github.com/nvim-lua/plenary.nvim',
}

local harpoon = require 'harpoon'

harpoon:setup {}

pcall(function()
  require('which-key').add {
    { '<leader>m', group = 'Harpoon' },
  }
end)

vim.keymap.set('n', '<leader>ma', function() harpoon:list():add() end, { desc = 'Harpoon add file' })
vim.keymap.set('n', '<leader>mm', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'Harpoon menu' })

vim.keymap.set('n', '<leader>m1', function() harpoon:list():select(1) end, { desc = 'Harpoon file 1' })
vim.keymap.set('n', '<leader>m2', function() harpoon:list():select(2) end, { desc = 'Harpoon file 2' })
vim.keymap.set('n', '<leader>m3', function() harpoon:list():select(3) end, { desc = 'Harpoon file 3' })
vim.keymap.set('n', '<leader>m4', function() harpoon:list():select(4) end, { desc = 'Harpoon file 4' })

vim.keymap.set('n', '<leader>mp', function() harpoon:list():prev() end, { desc = 'Harpoon previous file' })
vim.keymap.set('n', '<leader>mn', function() harpoon:list():next() end, { desc = 'Harpoon next file' })
