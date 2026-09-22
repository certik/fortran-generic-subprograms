! TEST-RULE: R712 R713 R714 C719 C721 C722 C723 7.5.3.2 7.5.7.2 15.6.2.4
! Inherited PDT parameters participate in a generic specifier. User-defined
! kind values zero and negative are legal because they are not used as
! intrinsic INTEGER(k) kinds. Calls with different runtime lengths share the
! same kind/rank specialization.
module language_pdt_inheritance_m
  implicit none
  type :: parent(k, n)
    integer, kind :: k
    integer, len :: n
    integer :: payload(n)
  end type
  type, extends(parent) :: child(extra)
    integer, kind :: extra = 9
    integer :: marker
  end type
contains
  generic subroutine inspect_child(x, k, n, extra, r, total)
    type(child(k=[-1, 0], n=*, extra=9)), rank(0:1), intent(in) :: x
    integer, intent(out) :: k, n, extra, r, total
    integer :: i
    k = x%k
    n = x%n
    extra = x%extra
    r = rank(x)
    select generic rank (x)
    rank (0)
      total = sum(x%payload) + x%marker
    rank (1)
      total = 0
      do i = 1, size(x)
        total = total + sum(x(i)%payload) + x(i)%marker
      end do
    end select
  end subroutine
end module

program language_pdt_inheritance_p
  use language_pdt_inheritance_m
  implicit none
  type(child(k=-1, n=2, extra=9)) :: short
  type(child(k=-1, n=5, extra=9)) :: long
  type(child(k=-1, n=1, extra=9)) :: neg_array(2)
  type(child(k=0, n=3, extra=9)) :: zero
  type(child(k=0, n=2, extra=9)) :: zero_array(2)
  integer :: k, n, extra, r, total

  short%payload = [1, 2]
  short%marker = 3
  long%payload = [1, 2, 3, 4, 5]
  long%marker = 5
  neg_array(1)%payload = [2]
  neg_array(1)%marker = 1
  neg_array(2)%payload = [3]
  neg_array(2)%marker = 2
  zero%payload = [4, 5, 6]
  zero%marker = 4
  zero_array(1)%payload = [1, 1]
  zero_array(1)%marker = 1
  zero_array(2)%payload = [2, 2]
  zero_array(2)%marker = 2

  call inspect_child(short, k, n, extra, r, total)
  call check(k, n, extra, r, total, -1, 2, 9, 0, 6)
  call inspect_child(long, k, n, extra, r, total)
  call check(k, n, extra, r, total, -1, 5, 9, 0, 20)
  call inspect_child(neg_array, k, n, extra, r, total)
  call check(k, n, extra, r, total, -1, 1, 9, 1, 8)
  call inspect_child(zero, k, n, extra, r, total)
  call check(k, n, extra, r, total, 0, 3, 9, 0, 19)
  call inspect_child(zero_array, k, n, extra, r, total)
  call check(k, n, extra, r, total, 0, 2, 9, 1, 9)
contains
  subroutine check(ak, an, ae, ar, av, ek, en, ee, er, ev)
    integer, intent(in) :: ak, an, ae, ar, av, ek, en, ee, er, ev
    if (ak /= ek .or. an /= en .or. ae /= ee .or. ar /= er .or. av /= ev) &
      error stop "inherited PDT"
  end subroutine
end program
