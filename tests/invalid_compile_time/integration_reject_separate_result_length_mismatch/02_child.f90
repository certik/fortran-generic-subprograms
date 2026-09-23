submodule (integration_reject_separate_result_length_mismatch_m) &
    integration_reject_separate_result_length_mismatch_s
  implicit none
contains
  ! TEST-ERROR-HERE
  module generic function framed(x) result(y)
    character(len=*, kind=kind('')), intent(in) :: x
    ! TEST-ERROR-HERE
    character(len=len(x) + 1, kind=kind('')) :: y
    y = '[' // x
  end function
end submodule
