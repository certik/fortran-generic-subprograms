! Invalid: C721. Each type parameter appears at most once.
module pdt_duplicate_param_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine s(x)
    type(t(k=[1, 2], k=[1, 2], n=*)) :: x
  end subroutine
end module
