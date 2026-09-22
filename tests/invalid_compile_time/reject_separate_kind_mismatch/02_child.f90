submodule (reject_separate_kind_mismatch_m) reject_separate_kind_mismatch_s
  use, intrinsic :: iso_fortran_env, only: int32
contains
  ! TEST-ERROR-HERE
  module generic subroutine s(x)
    integer([int32]) :: x
  end subroutine
end submodule
