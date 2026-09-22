! Invalid: C1159. A parameterized type with only scalar kind parameters is
! an ordinary derived-type spec, not a generic one (C723). SELECT GENERIC
! TYPE does not apply.
module pdt_scalar_not_generic_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine s(x)
    type(t(k=1, n=*)), intent(inout) :: x
    select generic type (x)
    declared type is (t(k=1, n=*))
      x%v = 1
    end select
  end subroutine
end module
