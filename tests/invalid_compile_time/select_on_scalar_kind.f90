! TEST-RULE: C1159 C723
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1159|not.*type-generic|selector.*type-generic dummy
! TEST-ERROR-PHASE: compile
! Invalid: C1159. INTEGER(KIND(0)) is an ordinary scalar kind selector, not a
! generic-intrinsic-type-spec. The dummy is not type-generic.
module select_on_scalar_kind_m
  implicit none
contains
  generic subroutine s(x)
    integer(kind(0)) :: x
    ! TEST-ERROR-HERE
    select generic type (x)
    declared type is (integer(kind(0)))
      x = 1
    end select
  end subroutine
end module
