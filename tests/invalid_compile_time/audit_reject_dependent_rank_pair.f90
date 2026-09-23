! TEST-RULE: R833 10.1.12p2 15.5.5.2 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: no matching specific|no specific procedure|no matching.*accept_pair|unable to resolve.*accept_pair|rank.*mismatch
! TEST-ERROR-PHASE: compile
module audit_reject_dependent_rank_pair_m
  implicit none
contains
  generic subroutine accept_pair(x, y)
    integer, rank(1:2), intent(in) :: x
    integer, rank(0:rank(x)), intent(in) :: y
  end subroutine
end module

program audit_reject_dependent_rank_pair_p
  use audit_reject_dependent_rank_pair_m
  implicit none
  integer :: vector(2), matrix(1, 1)

  vector = [1, 2]
  matrix = 3
  ! TEST-ERROR-HERE
  call accept_pair(vector, matrix)
end program
