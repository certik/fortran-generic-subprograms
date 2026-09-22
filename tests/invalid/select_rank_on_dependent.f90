! Invalid: C1155. y takes its rank from x; it is not a rank-generic dummy.
! The paper's example selected on the dependent result. Select on x instead.
module select_rank_on_dependent_m
  implicit none
contains
  generic subroutine s(x, y)
    integer, rank(0:2) :: x
    integer, rank(rank(x)) :: y
    select generic rank (y)
    rank (0)
      y = 0
    rank default
      y = 1
    end select
  end subroutine
end module
