# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

when defined(posix) and not defined(macosx):
  switch("define", "wayland")
  
