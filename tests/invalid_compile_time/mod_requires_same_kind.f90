! TEST-RULE: 15.6.2.4 15.5.5.1 15.5.5.2 17.9.158
! TEST-REQUIRES: real32 real64
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: MOD.*same kind|kind.*MOD|arguments.*kind|MOD.*(not consistent|inconsistent).*intrinsic|actual argument.*(bad|wrong|invalid) (type|kind)
! TEST-ERROR-PHASE: compile
! Nonconforming even though nothing calls it (15.6.2.4 p2, NOTE 3).
! The mixed-kind specifics pass two different kinds to MOD. INTRINSIC makes
! MOD a generic name (15.5.5.1 p2(3)); 15.5.5.2 p3 and p5 resolve the
! reference only if it is consistent with MOD, whose P shall have the type
! and kind of A (17.9.158).
! Enhanced is a conservative classification, not a claim that 4.2 p2(7)
! cannot apply; see "Intrinsic-signature diagnostic policy" in
! doc/auto-generic-subprograms.md.
module mod_requires_same_kind_m
  use, intrinsic :: iso_fortran_env, only: real32, real64
  implicit none
contains
  generic real function bad(x, y)
    intrinsic mod
    real([real32, real64]) :: x
    real([real32, real64]) :: y
    ! TEST-ERROR-HERE
    bad = mod(x, y)
  end function
end module
