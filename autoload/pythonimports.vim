function! pythonimports#filename2module(filename)
  " Figure out the dotted module name of the given filename

  " Look at the file name of the module that contains this tag.  Find the
  " nearest parent directory that does not have __init__.py.  Assume it is
  " directly included in PYTHONPATH.
  let pkg = fnamemodify(a:filename, ":p")
  let root = fnamemodify(pkg, ":h")

  " normalize paths
  let pythonPathsNorm = []
  for path in g:pythonPaths
    let path_without_slash = substitute(expand(path), "/$", "", "")
    call add(pythonPathsNorm, path_without_slash)
  endfor

  let found_dir = ""
  let found_path = ""
  while 1
    if index(pythonPathsNorm, root) != -1
      let found_path = root
      break
    endif
    if found_dir == "" && isdirectory(root . "/.git")
      let found_path = root
      break
    endif
    " if found_dir == "" && !filereadable(root . "/__init__.py")
    "   let found_dir = root
    "   " note: can't break here!  PEP 420 implicit namespace packages don't have __init__.py,
    "   " so we might find the actual package root in a parent directory beyond this one, via pythonPathsNorm
    " endif
    let newroot = fnamemodify(root, ":h")
    if newroot == root
      break
    endif
    let root = newroot
  endwhile
  if found_path != ""
    let root = found_path
  else
    let root = found_dir
  endif

  let pkg = strpart(pkg, strlen(root))
  " Convert the relative path into a Python dotted module name
  let pkg = substitute(pkg, "[.]py$", "", "")
  let pkg = substitute(pkg, ".__init__$", "", "")
  let pkg = substitute(pkg, "^/", "", "")
  let pkg = substitute(pkg, "^site-packages/", "", "")
  let pkg = substitute(pkg, "/", ".", "g")
  " Get rid of the last module name if it starts with an underscore, e.g.
  " zope.schema._builtinfields -> zope.schema
  let pkg = substitute(pkg, "[.]_[a-zA-Z0-9_]*$", "", "")
  return pkg
endfunction

function! pythonimports#filename2package(filename)
  let module = pythonimports#filename2module(a:filename)
  let pkg = pythonimports#package_of(module)
  return pkg
endfunction

function! pythonimports#package_of(module)
  let pkg = substitute(a:module, '[.]\=[^.]\+$', '', '')
  return pkg
endfunction

function! pythonimports#maybe_reload_config()
  if has('python') || has('python3')
    " XXX: wasteful -- I should check if the file's timestamp has changed
    " instead of parsing it every time
    pyx import python_imports
    pyx python_imports.parse_python_imports_cfg()
  endif
endfunction
