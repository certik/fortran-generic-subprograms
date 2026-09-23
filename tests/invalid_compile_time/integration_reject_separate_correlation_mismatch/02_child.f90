submodule (integration_reject_separate_correlation_mismatch_m) &
    integration_reject_separate_correlation_mismatch_s
  implicit none
contains
  ! TEST-ERROR-HERE
  module generic subroutine pair(x, y)
    integer, intent(in), rank(0:1) :: x
    ! TEST-ERROR-HERE
    integer, intent(inout), rank(1 - rank(x)) :: y
    y = sum([x])
  end subroutine
end submodule
