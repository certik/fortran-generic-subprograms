! TEST-RULE: C722
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C722|kind parameter.*rank one|rank-two.*kind
! TEST-ERROR-PHASE: compile
module reject_pdt_kind_rank_two_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: value
  end type
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(t(k=reshape([kind(0)], [1, 1]), n=*)) :: x
  end subroutine
end module
