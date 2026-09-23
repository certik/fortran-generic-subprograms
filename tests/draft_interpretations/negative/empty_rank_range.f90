! TEST-RULE: 8.5.17 15.6.2.4
! TEST-DRAFT: empty-expansion
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: empty.*rank|rank range.*(empty|no rank)|no specific
! TEST-ERROR-PHASE: compile
! Selected empty-expansion reading only. RANK(1:0) is a generic RANK clause
! whose range names no rank. Neither 8.5.17 nor 15.6.2.4 says whether that
! denotes zero specifics or is invalid, so this fixture records only the
! reading that requires a nonempty rank set. It is not settled conformance,
! and accepting the declaration is not a failure outside that profile.
module empty_rank_range_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    integer, rank(1:0) :: x
  end subroutine
end module
