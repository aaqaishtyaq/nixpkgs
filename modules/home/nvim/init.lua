
local o = vim.o
local w = vim.wo
local b = vim.bo

-- local utils = require('utils')

vim.g.mapleader = " "

b.autoindent = true
b.expandtab = true
b.softtabstop = 2
b.shiftwidth = 2
b.tabstop = 2
b.smartindent = true
b.modeline = false
o.backspace = [[indent,eol,start]]
o.hidden = true
w.winfixwidth = true
o.lazyredraw = true
o.splitbelow = true
o.splitright = true
w.cursorline = true
b.synmaxcol = 4000
w.number = true

w.list = true
if vim.fn.has('multi_byte') == 1 and vim.o.encoding == 'utf-8' then
  o.listchars = [[tab:▸ ,extends:❯,precedes:❮,nbsp:±,trail:…]]
else
  o.listchars = [[tab:> ,extends:>,precedes:<,nbsp:.,trail:_]]
end

w.colorcolumn = [[100]]
w.wrap = true

o.termguicolors = true

o.clipboard = [[unnamed,unnamedplus]]

o.scrolloff = 4

o.timeoutlen = 300

o.mouse = 'a'

o.completeopt = [[menuone,noinsert,noselect]]


-- utils.create_augroup({
--   {'FileType', '*', 'setlocal', 'shiftwidth=4'},
--   {'FileType', 'ocaml,lua', 'setlocal', 'shiftwidth=2'},
--   {'FileType', 'javascript', 'setlocal', 'shiftwidth=2', 'softtabstop=2', 'expandtab'},
--   {'FileType', 'python', 'setlocal', 'shiftwidth=4', 'softtabstop=4', 'expandtab'},
--   {'FileType', 'ruby,eruby', 'setlocal', 'shiftwidth=2', 'tabstop=2', 'expandtab'},
--   {'FileType', 'rust', 'setlocal', 'shiftwidth=4', 'tabstop=4', 'expandtab'},
--   {'FileType', 'go', 'setlocal', 'shiftwidth=4', 'tabstop=4'}
-- }, 'Tab2')

-- utils.create_augroup({
--   {'BufNewFile,BufReadPost', '*.md', 'set', 'filetype=markdown'},
--   {'BufRead,BufNewFile', '*.yapl', 'set', 'filetype=yapl'}
-- }, 'BufE')


local builtin = require('telescope.builtin')
vim.keymap.set('n', '<C-p>', builtin.find_files, {})

require("telescope").setup({
  update_cwd = true,
  -- respect_buf_cwd = true,
})

require("telescope").load_extension "file_browser"

require("fzf-lua").setup({ "fzf-vim" })
