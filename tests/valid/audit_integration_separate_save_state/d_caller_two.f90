module audit_integration_separate_save_state_caller_two_m
  use audit_integration_separate_save_state_reexport_m, only: tick
  implicit none
  private
  public :: two_integer, two_integer_vector, two_real, two_real_vector
  public :: two_complex, two_logical, two_text
contains
  integer function two_integer() result(count)
    count = tick(7)
  end function

  integer function two_integer_vector() result(count)
    integer :: values(2)
    values = [4, 5]
    count = tick(values)
  end function

  integer function two_real() result(count)
    count = tick(-1.5)
  end function

  integer function two_real_vector() result(count)
    count = tick([0.5])
  end function

  integer function two_complex() result(count)
    count = tick((0.0, 2.0))
  end function

  integer function two_logical() result(count)
    count = tick(.false.)
  end function

  integer function two_text(text) result(count)
    character(len=*), intent(in) :: text
    count = tick(text)
  end function
end module
