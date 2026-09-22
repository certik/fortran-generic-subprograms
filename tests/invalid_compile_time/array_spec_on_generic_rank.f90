! Invalid: C876. An entity with a generic RANK clause has no array-spec.
module array_spec_on_generic_rank_m
  implicit none
contains
  generic subroutine s(x)
    integer, rank(1:2) :: x(:)
  end subroutine
end module
