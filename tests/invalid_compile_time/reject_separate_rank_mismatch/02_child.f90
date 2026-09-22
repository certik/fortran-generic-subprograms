submodule (reject_separate_rank_mismatch_m) reject_separate_rank_mismatch_s
contains
  ! TEST-ERROR-HERE
  module generic subroutine s(x)
    integer, rank(0:2) :: x
  end subroutine
end submodule
