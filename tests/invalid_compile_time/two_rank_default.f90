! Invalid: C1156. At most one RANK DEFAULT.
module two_rank_default_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(0:1) :: x
    select generic rank (x)
    rank default
      x = 1
    rank default
      x = 2
    end select
  end subroutine
end module
