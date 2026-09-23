program separate_compilation_p
  use separate_compilation_m
  implicit none
  if (tag(3) /= 1) error stop "integer"
  if (tag(1.5) /= 2) error stop "real"
  print '(a)', 'TEST-PASS: separate_compilation'
end program
