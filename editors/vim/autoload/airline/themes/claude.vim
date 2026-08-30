" Airline theme assorti au colorscheme "claude" (palette café / terracotta).
" La palette est reconstruite dans refresh(), appelée par airline#load_theme() :
" le passage background=dark <-> light est donc suivi automatiquement.
let g:airline#themes#claude#palette = {}

function! airline#themes#claude#refresh() abort
  if &background ==# 'light'
    let l:bg     = ['#F7F2EE', 255]
    let l:bg_alt = ['#ECE5DF', 254]
    let l:bg_sel = ['#E1D7CF', 188]
    let l:fg     = ['#3A332D', 236]
    let l:fg_dim = ['#6D645D', 241]
    let l:accent = ['#A34C28', 130]
    let l:string = ['#497738', 239]
    let l:gold   = ['#816512',  94]
    let l:red    = ['#A63340', 131]
    let l:blue   = ['#3E6C9B',  60]
  else
    let l:bg     = ['#1C1916', 234]
    let l:bg_alt = ['#27221E', 235]
    let l:bg_sel = ['#3A332D', 236]
    let l:fg     = ['#E9E1DB', 254]
    let l:fg_dim = ['#B5ACA5', 145]
    let l:accent = ['#E3835C', 173]
    let l:string = ['#7CB169', 107]
    let l:gold   = ['#C09B34', 136]
    let l:red    = ['#EC6771', 203]
    let l:blue   = ['#74A4D6', 110]
  endif

  " section B (branche git) et C (chemin) sont communes à tous les modes :
  " seul le bloc A change de couleur, c'est lui qui signale le mode.
  let l:b = [l:fg[0],     l:bg_sel[0], l:fg[1],     l:bg_sel[1]]
  let l:c = [l:fg_dim[0], l:bg_alt[0], l:fg_dim[1], l:bg_alt[1]]
  let l:Mode = { a -> airline#themes#generate_color_map(
        \ [l:bg[0], a[0], l:bg[1], a[1]], l:b, l:c) }

  let l:p = g:airline#themes#claude#palette
  let l:p.normal   = l:Mode(l:accent)
  let l:p.insert   = l:Mode(l:string)
  let l:p.replace  = l:Mode(l:red)
  let l:p.visual   = l:Mode(l:gold)
  let l:p.terminal = l:Mode(l:blue)
  let l:p.inactive = airline#themes#generate_color_map(l:c, l:c, l:c)

  let l:warn = [l:bg[0], l:gold[0], l:bg[1], l:gold[1]]
  let l:err  = [l:bg[0], l:red[0],  l:bg[1], l:red[1]]
  for l:m in ['normal', 'insert', 'replace', 'visual', 'terminal', 'inactive']
    let l:p[l:m].airline_warning = l:warn
    let l:p[l:m].airline_error   = l:err
  endfor

  let l:p.accents = { 'red': [l:red[0], '', l:red[1], ''] }
endfunction

call airline#themes#claude#refresh()
