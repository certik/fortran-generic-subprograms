! TEST-RULE: R705 R1155 R1157 11.1.11.2
! TEST-PASS: select_type_default
! DECLARED TYPE DEFAULT, and a specific for which no guard matches
! (11.1.11). The real specific of unmarked contains no block; y stays 0.
module select_type_default_m
  implicit none
contains
  generic function code(x) result(n)
    type(integer, real, logical), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (integer)
      n = 1
    declared type default
      n = -1
    end select
  end function

  generic function unmarked(x) result(y)
    type(integer, real), intent(in) :: x
    integer :: y
    y = 0
    select generic type (x)
    declared type is (integer)
      y = 1
    end select
  end function
end module

program select_type_default_p
  use select_type_default_m
  implicit none
  if (code(3) /= 1) error stop "integer guard"
  if (code(3.0) /= -1) error stop "real default"
  if (code(.true.) /= -1) error stop "logical default"
  if (unmarked(3) /= 1) error stop "integer block"
  if (unmarked(3.0) /= 0) error stop "real has no block"
  print '(a)', 'TEST-PASS: select_type_default'
end program
