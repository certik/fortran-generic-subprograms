! TEST-RULE: 7.3.2.2p3
! TEST-DRAFT: mixed-length-dedup
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: duplicate.*length|assumed.*deferred.*length|inconsistent.*length
! TEST-ERROR-PHASE: compile
! Selected mixed-length-dedup reading only. 7.3.2.2 p3 collapses duplicate
! type/kind combinations but does not say which length mode survives when
! assumed and deferred entries otherwise coincide; this fixture records the
! reading that rejects the combination. There is no type guard here.
module reject_mixed_length_mode_dedup_m
  implicit none
contains
  generic subroutine s(x)
    ! TEST-ERROR-HERE
    type(character(len=*), character(len=:)), allocatable :: x
  end subroutine
end module
