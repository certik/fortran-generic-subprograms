module audit_integration_separate_save_state_caller_one_m
  use audit_integration_separate_save_state_counter_m, only: bump
  implicit none
  private
  public :: one_integer, one_integer_vector, one_real, one_real_vector
  public :: one_complex, one_logical
contains
  integer function one_integer(n) result(count)
    integer, intent(in) :: n
    count = bump(n)
  end function

  integer function one_integer_vector() result(count)
    count = bump([1, 2, 3])
  end function

  integer function one_real() result(count)
    count = bump(2.5)
  end function

  integer function one_real_vector() result(count)
    count = bump([1.0, 2.0])
  end function

  integer function one_complex() result(count)
    count = bump((1.0, -1.0))
  end function

  integer function one_logical() result(count)
    count = bump(.true.)
  end function
end module
