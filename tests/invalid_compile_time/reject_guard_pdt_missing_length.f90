! TEST-RULE: C1160
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1160|(length|len) type parameters?.*assumed|missing.*assumed length
! TEST-ERROR-PHASE: compile
! Invalid: C1160. The PDT guard omits its length parameter, so it takes
! a nonassumed length. Settled under either assumed-length-guards reading:
! whether or not a guard may spell an assumed length with *, an omitted
! length does not specify that the length parameter is assumed.
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
