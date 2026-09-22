submodule (reject_separate_nonrecursive_mismatch_m) reject_separate_nonrecursive_mismatch_s
contains
  ! TEST-ERROR-HERE
  module generic subroutine s(x)
    integer, intent(in) :: x
  end subroutine
end submodule
