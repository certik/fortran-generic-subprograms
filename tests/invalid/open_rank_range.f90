! Invalid syntax. A rank range needs both bounds (R833). The paper's RANK(1:)
! is not in 26-007r1; write RANK(1:MAX_RANK()).
module open_rank_range_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(1:) :: x
  end subroutine
end module
