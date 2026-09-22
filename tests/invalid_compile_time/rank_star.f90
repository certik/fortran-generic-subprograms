! TEST-RULE: R1152
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: RANK.*asterisk|invalid.*RANK.*guard|expected.*rank
! TEST-ERROR-PHASE: compile
! Invalid syntax. RANK(*) is a SELECT RANK guard for assumed size, not a
! rank-spec in SELECT GENERIC RANK.
module rank_star_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    select generic rank (x)
    ! TEST-ERROR-HERE
    rank (*)
      x = 1
    end select
  end subroutine
end module
