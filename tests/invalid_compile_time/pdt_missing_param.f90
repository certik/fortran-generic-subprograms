! Invalid: C721. A kind parameter with no default has to appear in the spec.
module pdt_missing_param_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine s(x)
    type(t(n=*)) :: x
  end subroutine
end module
