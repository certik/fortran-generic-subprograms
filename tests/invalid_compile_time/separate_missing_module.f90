! TEST-RULE: 15.4.3.2p4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: undefined reference.*inc|unresolved.*inc|symbol.*inc.*not found
! TEST-ERROR-PHASE: link
! Invalid: 15.4.3.2 p4. Dropping MODULE does not define the separate module
! procedure. The interface is then a procedure with no definition, and this
! program references it.
module separate_missing_module_m
  implicit none
  interface
    module generic function inc(n) result(r)
      integer, intent(in) :: n
      integer :: r
    end function
  end interface
end module

submodule (separate_missing_module_m) separate_missing_module_s
contains
  ! TEST-ERROR-HERE
  generic function inc(n) result(r)
    integer, intent(in) :: n
    integer :: r
    r = n + 1
  end function
end submodule

program separate_missing_module_p
  use separate_missing_module_m
  implicit none
  ! TEST-ERROR-HERE
  if (inc(1) /= 2) error stop "inc"
end program
