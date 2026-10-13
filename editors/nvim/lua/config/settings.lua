-----------------------------------------------------------
-- Options
-----------------------------------------------------------
local opt = vim.opt

-- Numeros de ligne
opt.relativenumber = true
opt.number = true

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Retour a la ligne
opt.wrap = true
opt.linebreak = true
opt.showbreak = "↪ "

-- Recherche
opt.ignorecase = true
opt.smartcase = true
-- :s/foo/bar/ agit sur toute la ligne sans avoir a taper /g
opt.gdefault = true

-- Apparence
opt.cursorline = true
opt.termguicolors = true
opt.background = "dark"
-- Le colorscheme est applique dans init.lua, apres lazy : xcodedark vient d'un
-- plugin, absent du runtimepath a ce stade.
-- Gouttiere toujours visible : sans ca le texte saute d'une colonne des qu'un
-- hunk git ou un diagnostic apparait.
opt.signcolumn = "yes"
-- Toujours 8 lignes de contexte autour du curseur
opt.scrolloff = 8
opt.sidescrolloff = 8
-- Rend visibles les caracteres qui se voient sinon uniquement en diff
opt.list = true
opt.listchars = {
  tab = "→ ",
  trail = "•",
  nbsp = "␣",
  extends = "⟩",
  precedes = "⟨",
}

-- Edition
opt.backspace = "indent,eol,start"
opt.splitright = true
opt.splitbelow = true
-- Le tiret fait partie du mot (utile en verilog/asciidoc)
opt.iskeyword:append("-")

-- Presse-papiers systeme
opt.clipboard:append("unnamedplus")

-- Historique persistant : undo conserve entre deux sessions, sauvegardes et
-- fichiers d'echange ranges hors de l'arborescence du projet.
local state = vim.fn.stdpath("state")
opt.undofile = true
opt.undodir = state .. "/undo//"
opt.backup = true
opt.backupdir = state .. "/backup//"
opt.directory = state .. "/swap//"
for _, dir in ipairs({ "undo", "backup", "swap" }) do
  vim.fn.mkdir(state .. "/" .. dir, "p", tonumber("700", 8))
end

-- Ecrit le buffer avant un :make, un :next, un changement de buffer...
opt.autowrite = true

-- Ignore dans les completions de chemin et les listings
opt.wildignore:append({
  "*.o", "*.obj", "*.a", "*.so", "*.dylib", "*.exe", "*.pyc", "*.class",
  "*.zip", "*.tar.gz", "*.png", "*.jpg", "*.gif", "*.pdf",
  "*/node_modules/*", "*/.git/*", "*/__pycache__/*", "*/.venv/*",
  ".DS_Store",
})

if vim.fn.has("wsl") == 1 then
  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("Yank", { clear = true }),
    callback = function()
      vim.fn.system("clip.exe", vim.fn.getreg('"'))
    end,
  })
end

-----------------------------------------------------------
-- Mappings
-----------------------------------------------------------
vim.g.mapleader = " "
vim.g.maplocalleader = ","

local keymap = vim.keymap
local function map(mode, lhs, rhs, desc)
  keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

-- Sortie du mode insertion dans les deux sens
map("i", "jk", "<ESC>", "Mode normal")
map("i", "kj", "<ESC>", "Mode normal")

-- Surbrillance de recherche
map("n", "<leader>nh", ":nohl<CR>", "Eteindre la surbrillance")
map("n", "<Esc><Esc>", ":nohl<CR>", "Eteindre la surbrillance")

-- Supprime un caractere sans polluer le registre
map("n", "x", '"_x')

-- Incrementer / decrementer
map("n", "<leader>+", "<C-a>", "Incrementer")
map("n", "<leader>-", "<C-x>", "Decrementer")

-- Navigation entre fenetres, sans passer par <C-w>
map("n", "<C-h>", "<C-w>h", "Fenetre a gauche")
map("n", "<C-j>", "<C-w>j", "Fenetre en bas")
map("n", "<C-k>", "<C-w>k", "Fenetre en haut")
map("n", "<C-l>", "<C-w>l", "Fenetre a droite")

-- Redimensionnement aux fleches
map("n", "<C-Up>", ":resize +2<CR>", "Agrandir en hauteur")
map("n", "<C-Down>", ":resize -2<CR>", "Reduire en hauteur")
map("n", "<C-Left>", ":vertical resize -2<CR>", "Reduire en largeur")
map("n", "<C-Right>", ":vertical resize +2<CR>", "Agrandir en largeur")

-- Splits
map("n", "<leader>sv", "<C-w>v", "Split vertical")
map("n", "<leader>sh", "<C-w>s", "Split horizontal")
map("n", "<leader>se", "<C-w>=", "Egaliser les splits")
map("n", "<leader>sx", ":close<CR>", "Fermer le split")

-- Onglets
map("n", "<leader>to", ":tabnew<CR>", "Nouvel onglet")
map("n", "<leader>tx", ":tabclose<CR>", "Fermer l'onglet")
map("n", "<leader>tn", ":tabn<CR>", "Onglet suivant")
map("n", "<leader>tp", ":tabp<CR>", "Onglet precedent")

-- Buffers
map("n", "<leader>bn", ":bnext<CR>", "Buffer suivant")
map("n", "<leader>bp", ":bprevious<CR>", "Buffer precedent")
map("n", "<leader>bd", ":bdelete<CR>", "Fermer le buffer")
map("n", "<leader>bl", ":buffers<CR>", "Lister les buffers")

-- Ecriture
map("n", "<leader>w", ":write<CR>", "Enregistrer")

-- Garde la selection apres un decalage d'indentation
map("v", "<", "<gv", "Desindenter")
map("v", ">", ">gv", "Indenter")

-- Deplacer la ligne ou la selection
map("n", "<A-j>", ":m .+1<CR>==", "Descendre la ligne")
map("n", "<A-k>", ":m .-2<CR>==", "Monter la ligne")
map("i", "<A-j>", "<Esc>:m .+1<CR>==gi", "Descendre la ligne")
map("i", "<A-k>", "<Esc>:m .-2<CR>==gi", "Monter la ligne")
map("v", "<A-j>", ":m '>+1<CR>gv=gv", "Descendre la selection")
map("v", "<A-k>", ":m '<-2<CR>gv=gv", "Monter la selection")

-- Molette sur un volet de diff non focalise : nvim ne propage scrollbind que
-- depuis la fenetre courante, donc le volet survole defilait seul. On lui donne
-- le focus avant de defiler.
local function wheel_in_diff(key)
  local code = vim.api.nvim_replace_termcodes(key, true, false, true)
  return function()
    local win = vim.fn.getmousepos().winid
    if win ~= 0 and win ~= vim.api.nvim_get_current_win() and vim.wo[win].diff and vim.wo[win].scrollbind then
      vim.api.nvim_set_current_win(win)
    end
    vim.cmd.normal({ code, bang = true })
  end
end
map("n", "<ScrollWheelUp>", wheel_in_diff("<ScrollWheelUp>"), "Molette haut")
map("n", "<ScrollWheelDown>", wheel_in_diff("<ScrollWheelDown>"), "Molette bas")

-----------------------------------------------------------
-- Autocommandes
-----------------------------------------------------------
local group = vim.api.nvim_create_augroup("user-settings", { clear = true })

-- Rouvre un fichier a l'endroit ou on l'avait quitte
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function(ev)
    if vim.bo[ev.buf].filetype:match("commit") then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Enregistre tout des que le terminal perd le focus
vim.api.nvim_create_autocmd("FocusLost", {
  group = group,
  command = "silent! wall",
})

-- Supprime les espaces en fin de ligne au save, sans bouger le curseur
vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function()
    if vim.bo.binary or vim.bo.filetype == "diff" then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Surligne brievement ce qui vient d'etre copie
vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-----------------------------------------------------------
-- Commandes
-----------------------------------------------------------
vim.api.nvim_create_user_command("Hexedit", "%!xxd", { desc = "Passer le buffer en hexadecimal" })
vim.api.nvim_create_user_command("HexeditRevert", "%!xxd -r", { desc = "Revenir du mode hexadecimal" })
vim.api.nvim_create_user_command("TrailingRemove", [[%s/\s\+$//e]], { desc = "Supprimer les espaces de fin" })
vim.api.nvim_create_user_command("EditConfig", function()
  vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua")
end, { desc = "Ouvrir la configuration" })
vim.api.nvim_create_user_command("ReloadConfig", function()
  vim.cmd("source " .. vim.fn.stdpath("config") .. "/init.lua")
  vim.notify("Configuration rechargee")
end, { desc = "Recharger la configuration" })
