program audit_integration_bind_c_abi_p
  use, intrinsic :: iso_c_binding, only: c_int
  use audit_integration_bind_c_abi_m, only: call_count
  implicit none
  interface
    function call_from_c() result(status) bind(c, name="fgs_audit_call_generic")
      import c_int
      integer(c_int) :: status
    end function
  end interface
  integer(c_int) :: status

  status = call_from_c()
  if (status /= 0_c_int) error stop "C label, VALUE argument, or result ABI"
  if (call_count /= 2) error stop "C did not enter both calls"
  print '(a)', 'TEST-PASS: audit-integration-bind-c-abi'
end program
