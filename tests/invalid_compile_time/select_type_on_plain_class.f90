! TEST-RULE: C1159
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1159|CLASS.*not.*type-generic|selector.*type-generic dummy
! TEST-ERROR-PHASE: compile
! Invalid: C1159. CLASS(t) is an ordinary polymorphic type spec, not a
! generic-type-spec (C716). The dummy is rank-generic only.
module select_type_on_plain_class_m
  implicit none
  type :: t
    integer :: n
  end type
contains
  generic subroutine s(x)
    class(t), rank(0:1) :: x
    ! TEST-ERROR-HERE
    select generic type (x)
    declared type is (t)
      x%n = 1
    end select
  end subroutine
end module
