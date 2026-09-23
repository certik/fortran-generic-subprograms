submodule (integration_reject_separate_result_attribute_mismatch_m) &
    integration_reject_separate_result_attribute_mismatch_s
  implicit none
contains
  ! TEST-ERROR-HERE
  module generic function copy(x) result(y)
    integer, intent(in) :: x(:)
    ! TEST-ERROR-HERE
    integer, pointer :: y(:)
    allocate(y, source=x)
  end function
end submodule
