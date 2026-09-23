! TEST-RULE: R705 R712 R713 R714 C715 C719 C721 C722 C723 C7121 7.5.9
! TEST-PASS: language_pdt_defaults
! Defaulted PDT kind parameters may be omitted in an ordinary guard. The PDT
! has no length parameter, so this does not depend on assumed-length guards.
! Scalar and rank-array factors are both exercised, as is CLASS with a
! kind-generic PDT.
module language_pdt_defaults_m
  implicit none
  type :: box(k)
    integer, kind :: k = 1
    integer :: value
  end type
contains
  generic subroutine inspect_box(x, code, total)
    type(box(k=[1, 2])), rank(0:1), intent(in) :: x
    integer, intent(out) :: code, total
    select generic type (x)
    declared type is (box)
      code = 100
    declared type is (box(k=2))
      code = 200
    end select
    select generic rank (x)
    rank (0)
      code = code + 0
      total = x%value
    rank (1)
      code = code + 1
      total = sum(x%value)
    end select
  end subroutine

  generic function inspect_class(x) result(n)
    class(box(k=[1, 2])), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (box)
      n = 1000 + x%value
    declared type is (box(k=2))
      n = 2000 + x%value
    end select
  end function
end module

program language_pdt_defaults_p
  use language_pdt_defaults_m
  implicit none
  type(box) :: b1
  type(box(k=1)) :: a1(2)
  type(box(k=2)) :: b2
  type(box(k=2)) :: a2(2)
  integer :: code, total

  b1%value = 3
  a1(1)%value = 4
  a1(2)%value = 5
  b2%value = 6
  a2(1)%value = 7
  a2(2)%value = 8
  call inspect_box(b1, code, total)
  if (code /= 100 .or. total /= 3 .or. b1%k /= 1) error stop "default box scalar"
  call inspect_box(a1, code, total)
  if (code /= 101 .or. total /= 9 .or. rank(a1) /= 1) error stop "default box array"
  call inspect_box(b2, code, total)
  if (code /= 200 .or. total /= 6 .or. b2%k /= 2) error stop "box kind2 scalar"
  call inspect_box(a2, code, total)
  if (code /= 201 .or. total /= 15 .or. rank(a2) /= 1) error stop "box kind2 array"
  if (inspect_class(b1) /= 1003) error stop "class defaulted kind"
  if (inspect_class(b2) /= 2006) error stop "class explicit kind"
  print '(a)', 'TEST-PASS: language_pdt_defaults'
end program
