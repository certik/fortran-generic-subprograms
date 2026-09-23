submodule (integration_reject_separate_result_shape_mismatch_m) &
    integration_reject_separate_result_shape_mismatch_s
  implicit none
contains
  ! TEST-ERROR-HERE
  module generic function spread(x) result(y)
    integer, intent(in) :: x(:)
    ! TEST-ERROR-HERE
    integer :: y(2*size(x))
    y = 0
    y(1:size(x)) = x
  end function
end submodule
