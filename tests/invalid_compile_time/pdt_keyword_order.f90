! Invalid: C720. Once a type-parameter keyword is used, the rest use keywords.
module pdt_keyword_order_m
  implicit none
  type :: t(k1, k2, n)
    integer, kind :: k1, k2
    integer, len :: n
    integer :: flag
  end type
contains
  generic subroutine s(x)
    type(t(k1=[1, 2], [1, 2], n=*)) :: x
  end subroutine
end module
