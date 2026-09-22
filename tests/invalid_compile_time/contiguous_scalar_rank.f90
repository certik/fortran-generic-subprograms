! Nonconforming: the rank-0 specific is a scalar with CONTIGUOUS (C834).
! Every specific is checked, including ones a program might not call.
module contiguous_scalar_rank_m
  implicit none
contains
  generic subroutine s(x)
    integer, contiguous, rank(0:1) :: x
  end subroutine
end module
