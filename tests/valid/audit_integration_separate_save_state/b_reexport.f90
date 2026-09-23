module audit_integration_separate_save_state_reexport_m
  use audit_integration_separate_save_state_counter_m, only: tick => bump
  implicit none
  private
  public :: tick
  interface tick
    module procedure tick_text
  end interface
contains
  function tick_text(x) result(count)
    character(len=*), intent(in) :: x
    integer :: count
    integer, save :: calls = 0
    calls = calls + 1
    count = 1000 + 10*len(x) + calls
  end function
end module
