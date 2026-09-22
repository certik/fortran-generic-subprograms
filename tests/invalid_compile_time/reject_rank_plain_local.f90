! TEST-RULE: C877
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C877|RANK.*(dummy|allocatable|pointer|constant)|local.*RANK
! TEST-ERROR-PHASE: compile
module reject_rank_plain_local_m
  implicit none
contains
  subroutine s()
    ! TEST-ERROR-HERE
    integer, rank(0) :: local
  end subroutine
end module
