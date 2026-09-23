! TEST-RULE: 11.1.10.2 11.1.11.2 11.2.1
! TEST-PASS: branch_to_end_select
! A branch to the END SELECT of SELECT GENERIC is allowed from inside the
! construct (11.1.10.2, 11.1.11.2).
module branch_to_end_select_m
  implicit none
contains
  generic function code(x) result(n)
    type(integer, real), rank(0:1), intent(in) :: x
    integer :: n
    n = 0
    outer: select generic type (x)
    declared type is (integer) outer
      inner: select generic rank (x)
      rank (0) inner
        n = 1
        go to 20
      rank (1) inner
        n = 2
        go to 20
      20 end select inner
      go to 10
    declared type is (real) outer
      n = 3
      go to 10
    10 end select outer
  end function
end module

program branch_to_end_select_p
  use branch_to_end_select_m
  implicit none
  integer :: v(1)
  real :: r(1)
  if (code(5) /= 1) error stop "integer scalar"
  if (code(v) /= 2) error stop "integer rank1"
  if (code(1.0) /= 3) error stop "real scalar"
  if (code(r) /= 3) error stop "real rank1"
  print '(a)', 'TEST-PASS: branch_to_end_select'
end program
