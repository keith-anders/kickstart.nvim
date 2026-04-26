-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

vim.pack.add {
  { src = 'https://github.com/nvim-neo-tree/neo-tree.nvim', version = vim.version.range '*' },
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/MunifTanjim/nui.nvim',
}

vim.keymap.set('n', '\\', '<Cmd>Neotree reveal<CR>', { desc = 'NeoTree reveal', silent = true })

require('neo-tree').setup {
  filesystem = {
    -- Don't auto-open neo-tree when Neovim starts on a directory (e.g. `nvim .`).
    -- Opening a directory falls back to netrw; open the tree on demand with `\`.
    hijack_netrw_behavior = 'disabled',
    window = {
      mappings = {
        ['\\'] = 'close_window',
      },
    },
  },
}
