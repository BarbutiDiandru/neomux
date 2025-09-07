return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      {
        "nvim-lua/plenary.nvim"
      },
      {
        "BurntSushi/ripgrep"
      },
    },

    config = function()
      require('telescope').setup {
        defaults = require('telescope.themes').get_ivy {},
        pickers = {
          find_files = {
            find_command = {
              "rg",
              "--files",
              "--ignore",
              "--hidden",
              "--glob=!.git"
            },
          },
          live_grep = {
            additional_args = {
              "--hidden",
              "--glob=!.git",
            },
          },
        }
      }
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Telescope find files' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Telescope live_grep' })
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = 'Telescope help tags' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = 'Telescope diagnostics' })
      vim.keymap.set('n', '<leader>sc', builtin.colorscheme, { desc = 'Telescope colorschemes' })
    end
  }
}
