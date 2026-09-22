submodule (reject_separate_attribute_mismatch_m) reject_separate_attribute_mismatch_s
contains
  ! TEST-ERROR-HERE
  module generic subroutine s(x)
    integer, intent(inout) :: x
    x = x + 1
  end subroutine
end submodule
