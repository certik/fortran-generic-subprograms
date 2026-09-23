program integration_module_interface_singleton_p
  use integration_module_interface_singleton_m, only: routed_singleton
  implicit none
  if (routed_singleton(9) /= 10) error stop "singleton enclosing generic"
  print '(a)', 'TEST-PASS: integration_module_interface_singleton'
end program
