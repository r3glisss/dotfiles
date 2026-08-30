-- SystemVerilog / Verilog
--
-- Port de la configuration du .vimrc. Trois choses que verible ne fait pas tout
-- seul et qui font la difference sur du RTL reel :
--   1. *.v n'est pas detecte comme verilog (heuristique de contenu -> langage V
--      ou Coq). On force le filetype.
--   2. verible ne resout les symboles hors du fichier courant que s'il trouve un
--      'verible.filelist' a la racine du projet, sans glob : chaque fichier doit
--      y etre liste. On le regenere a chaque lecture/ecriture, le serveur le
--      relit a chaud.
--   3. les regles de lint se configurent par projet (.rules.verible_lint), ce qui
--      demande --rules_config_search au serveur.
--
-- Binaires attendus (mason les installe, cf. completion.lua) :
--   verible-verilog-ls, verible-verilog-format

--------------------------------------------------------------------------------
-- 1. Detection du filetype
--------------------------------------------------------------------------------
vim.filetype.add({
  extension = {
    v = "verilog",
    vh = "verilog",
    sv = "systemverilog",
    svh = "systemverilog",
    svi = "systemverilog",
    vlg = "verilog",
  },
})

-- Un seul parser tree-sitter pour les deux filetypes.
vim.treesitter.language.register("verilog", { "verilog", "systemverilog" })

--------------------------------------------------------------------------------
-- 2. verible.filelist : indexation projet pour le goto-definition inter-fichiers
--------------------------------------------------------------------------------
local SV_GLOBS = { "*.sv", "*.svh", "*.v", "*.vh" }

--- Racine du projet : le depot git s'il y en a un, sinon le dossier qui contient
--- deja un verible.filelist, sinon le dossier du fichier.
local function verible_root(file)
  local dir = vim.fs.dirname(vim.fn.fnamemodify(file, ":p"))
  local marker = vim.fs.find({ ".git", "verible.filelist" }, { path = dir, upward = true })[1]
  return marker and vim.fs.dirname(marker) or dir
end

--- Regenere <root>/verible.filelist. Retourne true si le contenu a change.
local function verible_sync(file)
  if not file or file == "" or vim.fn.filereadable(file) ~= 1 then
    return false
  end

  local root = verible_root(file)
  local path = root .. "/verible.filelist"

  local cmd
  if vim.fn.isdirectory(root .. "/.git") == 1 then
    -- 'ls-files -co --exclude-standard' voit les fichiers pas encore commites et
    -- ecarte tout seul les artefacts de build gitignores.
    cmd = { "git", "-C", root, "ls-files", "-co", "--exclude-standard", "--" }
    vim.list_extend(cmd, SV_GLOBS)
  else
    cmd = { "find", ".", "-type", "f" }
    for i, glob in ipairs(SV_GLOBS) do
      vim.list_extend(cmd, { i == 1 and "(" or "-o", "-name", glob })
    end
    table.insert(cmd, ")")
  end

  local out = vim.system(cmd, { cwd = root, text = true }):wait()
  if out.code ~= 0 then
    return false
  end

  local files = {}
  for _, line in ipairs(vim.split(out.stdout or "", "\n", { trimempty = true })) do
    table.insert(files, (line:gsub("^%./", "")))
  end
  table.sort(files)

  local current = vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}
  -- N'ecrit que si le contenu change : evite de faire vieillir le mtime et de
  -- declencher des rebuilds fantomes chez les outils qui lisent ce fichier.
  if vim.deep_equal(files, current) then
    return false
  end
  vim.fn.writefile(files, path)

  -- Garde le depot propre sans toucher au .gitignore partage de l'equipe.
  local exclude = root .. "/.git/info/exclude"
  if vim.fn.filereadable(exclude) == 1 then
    if not vim.list_contains(vim.fn.readfile(exclude), "verible.filelist") then
      vim.fn.writefile({ "verible.filelist" }, exclude, "a")
    end
  end
  return true
end

vim.api.nvim_create_user_command("VeribleFilelist", function()
  local changed = verible_sync(vim.api.nvim_buf_get_name(0))
  vim.notify(changed and "verible.filelist mis a jour" or "verible.filelist deja a jour")
end, { desc = "Regenere verible.filelist a la racine du projet" })

--------------------------------------------------------------------------------
-- 3. Reglages de buffer + regeneration automatique
--------------------------------------------------------------------------------
local group = vim.api.nvim_create_augroup("systemverilog", { clear = true })

-- sigcone : drivers et fanout du signal sous le curseur. Le module vit dans
-- lua/sigcone/ (en anglais), charge a la premiere ouverture d'un fichier RTL.
local sigcone_ready = false

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "verilog", "systemverilog" },
  callback = function(ev)
    if not sigcone_ready then
      require("sigcone").setup()
      sigcone_ready = true
    end
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
    end
    map("<leader>i", function()
      require("sigcone").toggle()
    end, "Inspect signal (drivers / fanout)")
    map("<leader>I", function()
      require("sigcone").quickfix()
    end, "Inspect signal (quickfix)")

    local bo = vim.bo[ev.buf]
    bo.tabstop = 2
    bo.softtabstop = 2
    bo.shiftwidth = 2
    bo.expandtab = true
    -- Colonne de garde : verible-verilog-format coupe a 100 par defaut
    vim.opt_local.colorcolumn = "100"

    -- Pas de formatage automatique au save sur du RTL : verible reindente le
    -- fichier entier et noie la revue dans du bruit. On garde le meme choix que
    -- le .vimrc -- formatage a la demande avec <leader>f.
    vim.b[ev.buf].disable_autoformat = true

    -- Backtick dans iskeyword : permet de sauter sur un `define avec * / gd /
    -- <C-]>. Doit passer APRES le chargement de la syntaxe -- $VIMRUNTIME/
    -- syntax/verilog.vim reaffecte iskeyword en dur, et l'evenement Syntax
    -- arrive apres FileType.
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then
        return
      end
      local isk = vim.bo[ev.buf].iskeyword
      if not isk:find("`", 1, true) then
        vim.bo[ev.buf].iskeyword = isk .. ",`"
      end
    end)
  end,
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  group = group,
  pattern = { "*.sv", "*.svh", "*.v", "*.vh" },
  callback = function(ev)
    verible_sync(vim.api.nvim_buf_get_name(ev.buf))
  end,
})

--------------------------------------------------------------------------------
-- 4. Serveurs de langage
--------------------------------------------------------------------------------
-- Repartition des roles :
--   slang-server -> navigation et semantique. Il ELABORE le design (bibliotheque
--                   slang), la ou verible ne fait qu'analyser la syntaxe : goto
--                   definition a travers la hierarchie, hover type, completion
--                   des membres de struct / interface / classe, inlay hints sur
--                   les ports et arguments, erreurs d'elaboration reelles.
--   verible      -> style. Formatage (conform) et lint de regles (nvim-lint),
--                   appeles en ligne de commande : plus de second serveur LSP,
--                   donc plus de diagnostics en double.
--
-- API native de nvim 0.11 : la config est fusionnee avec la config '*'
-- (capabilities blink.cmp) posee dans completion.lua.
vim.lsp.config("slang_server", {
  cmd = { "slang-server" },
  filetypes = { "verilog", "systemverilog" },
  -- `.slang` = fichier de config du serveur (cf. slang-server --config-schema)
  root_markers = { ".slang", "build.f", ".git" },
  settings = {
    -- Hints en ligne. `wildcardNames` developpe un `.*` en la liste reelle des
    -- ports connectes, `orderedInstanceNames` etiquette les connexions
    -- positionnelles : c'est ce qui fait gagner le plus de temps en relecture.
    -- Cles exactes : `slang-server --config-schema`.
    inlayHints = {
      portTypes = true,
      orderedInstanceNames = true,
      wildcardNames = true,
      funcArgNames = 2,
      macroArgNames = 2,
    },
  },
})
vim.lsp.enable("slang_server")

--------------------------------------------------------------------------------
-- 5. Specs de plugins
--------------------------------------------------------------------------------
return {
  -- Coloration syntaxique : grammaire gmlarumbe/tree-sitter-systemverilog.
  -- Le parser couvre les deux filetypes -- on le declare explicitement, sinon
  -- les buffers `verilog` restent sur la syntaxe regex du runtime.
  {
    "nvim-treesitter/nvim-treesitter",
    -- Listes concatenees grace a `opts_extend` declare dans treesitter.lua.
    -- Sur la branche master le parser s'appelle `verilog` (il a ete renomme en
    -- `systemverilog` sur main) ; c'est la meme grammaire.
    opts = {
      ensure_installed = { "verilog" },
      -- Indentation tree-sitter incomplete pour cette grammaire : l'indent natif
      -- de nvim ($VIMRUNTIME/indent/verilog.vim) fait mieux.
      indent = { disable = { "verilog" } },
    },
  },

  -- Formatage : verible-verilog-format, via <leader>f (cf. python.lua)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        verilog = { "verible" },
        systemverilog = { "verible" },
      },
    },
  },

  -- Lint de style : verible-verilog-lint. slang couvre la semantique, verible
  -- couvre les regles de style du projet (.rules.verible_lint, trouve grace a
  -- --rules_config_search). nvim-lint n'a pas de definition pour verible : on
  -- la fournit.
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        verilog = { "verible" },
        systemverilog = { "verible" },
      },
      linters = {
        verible = {
          cmd = "verible-verilog-lint",
          args = { "--rules_config_search" },
          stdin = false,
          append_fname = true,
          -- Le linter sort en erreur des qu'il trouve une violation.
          ignore_exitcode = true,
          -- verible-verilog-lint ecrit ses violations sur stderr et sort en 1
          stream = "stderr",
          parser = require("lint.parser").from_pattern(
            -- fichier:ligne:col[-col]: message [Style: categorie] [regle]
            "[^:]+:(%d+):(%d+)%S*: (.+)",
            { "lnum", "col", "message" },
            nil,
            { source = "verible", severity = vim.diagnostic.severity.WARN }
          ),
        },
      },
    },
  },
}
