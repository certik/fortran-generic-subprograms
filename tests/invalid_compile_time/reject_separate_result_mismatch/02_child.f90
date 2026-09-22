submodule (reject_separate_result_mismatch_m) reject_separate_result_mismatch_s
contains
  ! TEST-ERROR-HERE
  module generic function f(x) result(y)
    integer, intent(in) :: x
    real :: y
    y = real(x)
  end function
end submodule
