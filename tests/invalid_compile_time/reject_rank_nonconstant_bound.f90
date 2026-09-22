! TEST-RULE: R832 R833 C875
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: rank.*constant|constant expression.*RANK|nonconstant.*rank
! TEST-ERROR-PHASE: compile
module reject_rank_nonconstant_bound_m
  implicit none
contains
  generic subroutine s(n, x)
    integer, intent(in) :: n
    ! TEST-ERROR-HERE
    integer, rank(0:n) :: x
  end subroutine
end module
