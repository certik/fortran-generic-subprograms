! Invalid: 15.4.3.4.5. Both subprograms produce a rank-2 integer specific.
module overlapping_generics_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:2) :: x
    x = 1
  end subroutine
  generic subroutine s(x)
    integer, rank(2:4) :: x
    x = 2
  end subroutine
end module
