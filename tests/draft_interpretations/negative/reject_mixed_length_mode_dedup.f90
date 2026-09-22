! TEST-RULE: 7.3.2.2p3
! TEST-DRAFT: mixed-length-dedup assumed-length-guards
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: duplicate.*length|assumed.*deferred.*length|inconsistent.*length
! TEST-ERROR-PHASE: compile
module reject_mixed_length_mode_dedup_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(character(len=*), character(len=:)), allocatable :: x
  end subroutine
end module
