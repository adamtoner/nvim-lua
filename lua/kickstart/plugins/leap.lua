vim.pack.add {
  {
    name = 'leap.nvim',
    src = 'https://codeberg.org/andyg/leap.nvim',
    version = 'main',
  },
}

vim.keymap.set({ 'n', 'x', 'o' }, 's', function() require('leap').leap {} end, { desc = 'Leap forward' })
vim.keymap.set({ 'n', 'x', 'o' }, 'S', function() require('leap').leap { backward = true } end, { desc = 'Leap backward' })
