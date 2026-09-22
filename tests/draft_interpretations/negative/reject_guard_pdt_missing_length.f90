! TEST-RULE: C1160
! TEST-DRAFT: assumed-length-guards
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1160|length type parameter.*assumed|missing.*assumed length
! TEST-ERROR-PHASE: compile
module reject_guard_pdt_missing_length_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n = 1
    integer(k) :: value
  end type
contains
  generic subroutine s(x)
    type(t(k=[kind(0)], n=*)) :: x
    select generic type (x)
    ! TEST-ERROR-HERE
    declared type is (t(k=kind(0)))
      continue
    end select
  end subroutine
end module
