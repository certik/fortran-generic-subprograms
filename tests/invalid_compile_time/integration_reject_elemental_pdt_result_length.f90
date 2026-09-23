! TEST-RULE: C15138 15.6.2.4 15.9.1
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15138|elemental.*result.*(length|type parameter|dummy argument)|specification (expression|inquiry).*elemental|type parameter.*elemental.*(dummy|argument)
! TEST-ERROR-PHASE: compile
! The type parameter inquiry x%n would be permitted (see
! valid/audit_integration_elemental_result_params.f90). The value of the
! dummy WIDTH is not the subject of a specification inquiry, so both
! generated elemental PDT specifics violate C15138.
module integration_reject_elemental_pdt_result_length_m
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  implicit none
  type :: tagged(k, n)
    integer, kind :: k
    integer, len :: n
    real(k) :: weight
    character(len=n) :: label
  end type
contains
  elemental generic function resized(x, width) result(y)
    type(tagged(k=[single_precision, double_precision], n=*)), intent(in) :: x
    integer, intent(in) :: width
    ! TEST-ERROR-HERE
    type(tagged(k=x%k, n=width)) :: y
    y%weight = x%weight
    y%label = x%label
  end function
end module
