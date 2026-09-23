! TEST-RULE: C1561 8.7 15.4.3.2 15.6.2.6
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1561|characteristics.*(interface|separate|module procedure)|(mismatch|not compatible|distinct).*(interface|module procedure|declaration)|(interface|declaration).*(does not match|mismatch|differ|not compatible)
! TEST-ERROR-PHASE: compile
! Both declarations are spelled REAL. The MODULE GENERIC interface body has
! the standard default real kind (8.7 p3), while the defining module
! subprogram inherits DOUBLE_PRECISION from its module, so the singleton
! specific's characteristics differ (C1561). The valid counterpart is
! valid/audit_integration_default_kinds.f90.
module integration_reject_separate_default_kind_mismatch_m
  use, intrinsic :: iso_fortran_env, only: double_precision
  default kind (real = double_precision)
  implicit none
  interface
    module generic function scaled(x) result(y)
      real, intent(in) :: x
      real :: y
    end function
  end interface
contains
  ! TEST-ERROR-HERE
  module generic function scaled(x) result(y)
    ! TEST-ERROR-HERE
    real, intent(in) :: x
    real :: y
    y = 2*x
  end function
end module
