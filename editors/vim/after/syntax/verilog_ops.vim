" Sépare la ponctuation des vrais opérateurs en Verilog / SystemVerilog.
"
" vim-polyglot met TOUT dans un seul groupe :
"   syn match verilogOperator "[&|~><!)(*#%@+/=?:;}{,.^-[]]"
"   hi def link verilogOperator Special
" donc « & » et « ; » ou « ( » partagent la même couleur. On isole ici la
" ponctuation dans verilogPunct pour pouvoir la garder discrète et ne colorer
" que les opérateurs.
"
" NB : on ne redéfinit surtout pas verilogOperator — il contient « / » et « * »,
" et une redéfinition après les régions de commentaires casserait « // » et
" « /* */ » (le dernier item défini gagne).

if exists('b:claude_verilog_ops')
  finish
endif
let b:claude_verilog_ops = 1

syn match verilogPunct "[(){};,.]"
syn match verilogPunct "[][]"

hi def link verilogPunct Delimiter
