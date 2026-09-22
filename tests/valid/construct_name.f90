! TEST-RULE: C1157 C1158 C1163 R1150 R1155
! Construct names on SELECT GENERIC RANK and SELECT GENERIC TYPE (C1157, C1163).
module construct_name_m
  implicit none
contains
  generic function code(x) result(n)
    type(integer, real), rank(0:1), intent(in) :: x
    integer :: n
    outer: select generic type (x)
    declared type is (integer) outer
      inner: select generic rank (x)
      rank (0) inner
        n = 1
      rank (1) inner
        n = 2
      end select inner
    declared type is (real) outer
      n = 3
    end select outer
  end function
end module

program construct_name_p
  use construct_name_m
  implicit none
  real :: r(1)
  if (code(5) /= 1) error stop "integer scalar"
  if (code([5]) /= 2) error stop "integer rank1"
  if (code(1.0) /= 3) error stop "real scalar"
  if (code(r) /= 3) error stop "real rank1"
end program
