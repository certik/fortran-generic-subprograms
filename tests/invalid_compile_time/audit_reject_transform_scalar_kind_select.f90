! TEST-RULE: C718 C1159 10.1.12
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1159|not.*type-generic|SELECT GENERIC TYPE.*generic dummy|scalar kind.*not generic
! TEST-ERROR-PHASE: compile
module audit_reject_transform_scalar_kind_select_m
  implicit none
  integer, parameter :: fixed_kind = maxval([kind(0), kind(0)])
contains
  generic subroutine reject_scalar_kind(x)
    integer(fixed_kind), intent(in) :: x
    ! A scalar transformational constant remains an ordinary kind selector.
    ! TEST-ERROR-HERE
    select generic type (x)
    declared type is (integer(fixed_kind))
      continue
    end select
  end subroutine
end module
