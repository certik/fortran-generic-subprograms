submodule (reject_separate_dummy_name_mismatch_m) reject_separate_dummy_name_mismatch_s
contains
  ! TEST-ERROR-HERE
  module generic subroutine s(y)
    integer, intent(in) :: y
  end subroutine
end submodule
