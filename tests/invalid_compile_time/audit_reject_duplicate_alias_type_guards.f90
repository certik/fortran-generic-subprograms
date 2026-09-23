! TEST-RULE: C1161 7.5.2
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1161|duplicate.*(type|guard)|same derived type.*guard|aliases.*same type
! TEST-ERROR-PHASE: compile
module audit_reject_duplicate_alias_origin_m
  implicit none
  type :: token
    integer :: value
  end type
end module

module audit_reject_duplicate_alias_left_m
  use audit_reject_duplicate_alias_origin_m, only: left => token
  implicit none
  public :: left
end module

module audit_reject_duplicate_alias_right_m
  use audit_reject_duplicate_alias_origin_m, only: right => token
  implicit none
  public :: right
end module

module audit_reject_duplicate_alias_type_guards_m
  use audit_reject_duplicate_alias_left_m, only: left
  use audit_reject_duplicate_alias_right_m, only: right
  implicit none
contains
  generic subroutine reject_alias_guards(x)
    type(left, right), intent(in) :: x
    select generic type (x)
    declared type is (left)
      continue
    ! TEST-ERROR-HERE
    declared type is (right)
      continue
    end select
  end subroutine
end module
