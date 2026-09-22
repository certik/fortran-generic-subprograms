! TEST-RULE: C877
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C877|RANK.*(dummy|allocatable|pointer|constant)|function result.*RANK
! TEST-ERROR-PHASE: compile
module reject_rank_dependent_plain_result_m
  implicit none
contains
  function f(x) result(y)
    integer, intent(in) :: x
    ! TEST-ERROR-HERE
    integer, rank(rank(x)) :: y
    y = x
  end function
end module
