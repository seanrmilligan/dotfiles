define c
  continue
  refresh
end
define s
  step
  refresh
end
define fin
  finish
  refresh
end
define r
  runac
  refresh
end
define n
  next
  refresh
end
define pretty
  set print pretty on
  print $arg0
  set print pretty off
end

set python print-stack none
set history save on
set history filename ~/.gdb-history
set history size 9999999
set trust-readonly-sections on
