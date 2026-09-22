! Invalid. RANK(1:0) is a generic rank clause whose range names no rank.
! A rank-generic dummy has to have at least one rank after the range is
! expanded. The draft does not say this in a numbered constraint; the
! suite still rejects it.
module empty_rank_range_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(1:0) :: x
  end subroutine
end module
