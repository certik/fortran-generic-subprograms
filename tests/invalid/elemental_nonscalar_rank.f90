! Nonconforming: C15135. The rank-1 specific of an elemental procedure has
! a non-scalar dummy.
module elemental_nonscalar_rank_m
  implicit none
contains
  elemental generic subroutine s(x)
    integer, intent(inout), rank(0:1) :: x
    x = x + 1
  end subroutine
end module
