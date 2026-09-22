! TEST-RULE: C722
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C722|length type parameter.*(asterisk|colon)|array.*length parameter
! TEST-ERROR-PHASE: compile
! Invalid: C722. A length type parameter in a generic derived type spec is
! * or :, not an array. An array is what makes a kind parameter generic.
module pdt_length_array_m
  implicit none
  type t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine s(x)
      ! TEST-ERROR-HERE
      type(t(k=[kind(0)], n=[1, 2])) :: x
    end subroutine
  end module
