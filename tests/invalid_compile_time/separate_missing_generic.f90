! TEST-RULE: 15.4.3.2p4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: separate module procedure.*GENERIC|GENERIC.*corresponding interface|interface.*definition
! TEST-ERROR-PHASE: compile
! Invalid: 15.4.3.2 p4. The interface is MODULE GENERIC, so the defining
! subprogram needs both MODULE and GENERIC.
module separate_missing_generic_m
  implicit none
  interface
    module generic function inc(n) result(r)
      integer, intent(in) :: n
      integer :: r
    end function
  end interface
end module

submodule (separate_missing_generic_m) separate_missing_generic_s
contains
  ! TEST-ERROR-HERE
  module function inc(n) result(r)
    integer, intent(in) :: n
    integer :: r
    r = n + 1
  end function
end submodule
