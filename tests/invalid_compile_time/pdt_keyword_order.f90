! TEST-RULE: C720
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C720|keyword.*preceding|type parameter.*keyword
! TEST-ERROR-PHASE: compile
! Invalid: C720. Once a type-parameter keyword is used, the rest use keywords.
module pdt_keyword_order_m
  implicit none
  type :: t(k1, k2, n)
    integer, kind :: k1, k2
    integer, len :: n
    integer :: flag
  end type
contains
  generic subroutine s(x)
      ! TEST-ERROR-HERE
      type(t(k1=[kind(0)], [kind(0)], n=*)) :: x
    end subroutine
  end module
