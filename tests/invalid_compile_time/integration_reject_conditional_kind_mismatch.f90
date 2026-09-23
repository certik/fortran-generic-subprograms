! TEST-RULE: C1541 15.5.2.3 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1541|conditional.*(same|different|mismatch).*(type|kind)|consequent.*(type|kind)|kind type parameter.*consequent
! TEST-ERROR-PHASE: compile
! The consequents have different real kinds, so they would select different
! generated specifics; C1541 requires the same declared type and kind.
module integration_reject_conditional_kind_mismatch_m
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  implicit none
contains
  generic function describe(x) result(code)
    real([single_precision, double_precision]), intent(in) :: x
    integer :: code
    select generic type (x)
    declared type is (real(single_precision))
      code = 1
    declared type is (real(double_precision))
      code = 2
    end select
  end function
end module

program integration_reject_conditional_kind_mismatch_p
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  use integration_reject_conditional_kind_mismatch_m
  implicit none
  logical :: flag
  real(single_precision) :: narrow
  real(double_precision) :: wide
  flag = .true.
  narrow = 1.0_single_precision
  wide = 2.0_double_precision
  ! TEST-ERROR-HERE
  if (describe((flag ? narrow : wide)) /= 1) error stop "unreachable"
end program
