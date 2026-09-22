! TEST-RULE: R712 R713 R714 C719 C722 C723 15.6.2.4
! A scalar kind parameter is a fixed value, not a factor. k2's four values
! produce four specifics, all with k1 = kind(0.0) (C723, 7.3.2.2).
module pdt_scalar_kind_m
  implicit none
  type :: t(k1, k2, n)
    integer, kind :: k1, k2
    integer, len :: n
    real(k1) :: value(k2, n)
  end type
contains
  generic subroutine fill(x)
    type(t(k1=kind(0.0), k2=[1, 2, 4, 8], n=*)), intent(inout) :: x
    x%value = real(x%k2, kind(x%value))
  end subroutine
end module

program pdt_scalar_kind_p
  use pdt_scalar_kind_m
  implicit none
  integer, parameter :: ks = kind(0.0)
  type(t(k1=ks, k2=1, n=3)) :: a1
  type(t(k1=ks, k2=2, n=3)) :: a2
  type(t(k1=ks, k2=4, n=2)) :: a4
  type(t(k1=ks, k2=8, n=1)) :: a8
  call fill(a1)
  call fill(a2)
  call fill(a4)
  call fill(a8)
  if (a1%k1 /= ks .or. a1%k2 /= 1 .or. a1%n /= 3) error stop "a1"
  if (a2%k1 /= ks .or. a2%k2 /= 2 .or. a2%n /= 3) error stop "a2"
  if (a4%k1 /= ks .or. a4%k2 /= 4 .or. a4%n /= 2) error stop "a4"
  if (a8%k1 /= ks .or. a8%k2 /= 8 .or. a8%n /= 1) error stop "a8"
  if (any(abs(a1%value - 1.0) /= 0.0)) error stop "a1 value"
  if (any(abs(a2%value - 2.0) /= 0.0)) error stop "a2 value"
  if (any(abs(a4%value - 4.0) /= 0.0)) error stop "a4 value"
  if (any(abs(a8%value - 8.0) /= 0.0)) error stop "a8 value"
end program
