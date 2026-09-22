! TEST-RULE: C1156
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1156|more than one.*RANK DEFAULT|duplicate.*RANK DEFAULT
! TEST-ERROR-PHASE: compile
! Invalid: C1156. At most one RANK DEFAULT.
module two_rank_default_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    select generic rank (x)
    rank default
      x = 1
    ! TEST-ERROR-HERE
    rank default
      x = 2
    end select
  end subroutine
end module
