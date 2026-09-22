! PURE, SIMPLE, VALUE, CONTIGUOUS, OPTIONAL on a non-generic dummy, and
! argument keywords. A generic dummy itself cannot be OPTIONAL (C802).
module prefixes_m
  implicit none
contains
  pure generic function add(a, b) result(c)
    type(integer, real), intent(in) :: a
    typeof(a), intent(in) :: b
    typeof(a) :: c
    c = a + b
  end function

  simple generic function sub1(a) result(c)
    type(integer, real), intent(in) :: a
    typeof(a) :: c
    c = a - 1
  end function

  generic function total(x) result(s)
    integer, rank(1:2), value :: x
    integer :: s
    x = x + 1
    s = sum(x)
  end function

  generic function sumc(x) result(s)
    integer, contiguous, rank(1:2), intent(in) :: x
    integer :: s
    if (.not. is_contiguous(x)) error stop "contiguous dummy"
    s = sum(x)
  end function

  generic subroutine bump(x, n)
    type(integer, real), intent(inout) :: x
    integer, optional, intent(in) :: n
    if (present(n)) then
      x = x + n
    else
      x = x + 1
    end if
  end subroutine
end module

program prefixes_p
  use prefixes_m
  implicit none
  integer :: a(3), a_save(3), b(2, 2), v(6)
  integer :: n
  real :: r
  a = [1, 2, 3]
  a_save = a
  b = reshape([1, 2, 3, 4], [2, 2])
  v = [1, 2, 3, 4, 5, 6]
  if (add(2, 3) /= 5) error stop "pure integer"
  if (add(1.5, 2.5) /= 4.0) error stop "pure real"
  if (sub1(4) /= 3) error stop "simple integer"
  if (sub1(2.5) /= 1.5) error stop "simple real"
  if (total(a) /= 9) error stop "value rank1"
  if (any(a /= a_save)) error stop "value leaves actual"
  if (total(b) /= 14) error stop "value rank2"
  if (sumc(v(1:6:2)) /= 9) error stop "contiguous section"
  n = 10
  r = 1.5
  call bump(n)
  if (n /= 11) error stop "optional absent"
  call bump(x=r, n=3)
  if (r /= 4.5) error stop "keyword optional"
end program
