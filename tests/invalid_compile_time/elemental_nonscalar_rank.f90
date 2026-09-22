! TEST-RULE: C15135 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C15135|elemental.*dummy.*scalar|nonscalar.*elemental
! TEST-ERROR-PHASE: compile
! Nonconforming: C15135. The rank-1 specific of an elemental procedure has
! a non-scalar dummy.
module elemental_nonscalar_rank_m
  implicit none
contains
  elemental generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, intent(inout), rank(0:1) :: x
    x = x + 1
  end subroutine
end module
