let s:cmd = 'pt --nogroup --nocolor -g "'

let s:source =
      \ { 'name'                    : 'ptlist'
      \ , 'description'             : 'candidates from pt -g'
      \ , 'max_candidates'          : 30
      \ , 'hooks' : {}
      \ }

function! unite#sources#ptlist#define()
  return [s:source]
endfunction

function! s:build_candidates(candidate_list)
  let file_list = []
  for candidate in a:candidate_list
    let entry = {
          \ 'word'              : candidate,
          \ 'abbr'              : candidate,
          \ 'source'            : 'ptlist',
          \ 'action__path'      : candidate,
          \ 'kind'              : 'file'
          \	}
    call add(file_list, entry)
  endfor
  return file_list
endfunction

function! s:source.hooks.on_close(args, context)
  while !a:context.source__subproc.stdout.eof
    call a:context.source__subproc.stdout.read()
  endwhile
  call a:context.source__subproc.kill(9)
endfunction

function! s:source.async_gather_candidates(args, context)

  if !has_key(a:context, 'source__term') ||
        \ has_key(a:context, 'source__term') && a:context.source__term != a:context.input
    let a:context.source__term = a:context.input

    if has_key(a:context, 'source__subproc')
      call vimproc#kill(a:context.source__subproc.pid, 9)
      call remove(a:context, 'source__subproc')
    endif

    let a:context.source__subproc = vimproc#popen3(s:cmd . a:context.input . '"')
  endif

  let res = []
  if has_key(a:context, 'source__subproc')
    if !a:context.source__subproc.stdout.eof
      let res = a:context.source__subproc.stdout.read_lines()[:30]
    endif
    call map(res, 'iconv(v:val, &termencoding, &encoding)')
  endif
  let candidates = map(res, 'unite#util#substitute_path_separator(v:val)')

  return s:build_candidates(candidates)
endfunction
