! Invalid: C875. A rank bound is nonnegative.
module negative_rank_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(-1:1) :: x
  end subroutine
end module
