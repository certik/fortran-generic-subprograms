! TEST-RULE: C1517
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1517|ambiguous.*generic|not distinguishable|same generic.*specific
! TEST-ERROR-PHASE: compile
! Invalid: 15.4.3.4.5. Both subprograms produce a rank-2 integer specific.
module overlapping_generics_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:2) :: x
    x = 1
  end subroutine
  ! TEST-ERROR-HERE
  generic subroutine s(x)
    integer, rank(2:4) :: x
    x = 2
  end subroutine
end module
