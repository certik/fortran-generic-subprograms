! TEST-RULE: 15.3.2.2 15.5.2.9 15.6.2.4
! TEST-DIAGNOSTIC-CLASS: enhanced
! TEST-ERROR: (VOLATILE|volatile).*(coarray|actual|dummy)|coarray.*(VOLATILE|volatile)
! TEST-ERROR-PHASE: compile
! The selected specific has a VOLATILE coarray dummy, so its coarray actual
! shall be VOLATILE as well (15.5.2.9 p1); this actual is not. The matching
! call is valid/audit_integration_coarray_volatile.f90.
module integration_reject_volatile_coarray_mismatch_m
  implicit none
contains
  generic function volatile_peek(x) result(total)
    type(integer, real), volatile, intent(inout), rank(0:1) :: x[*]
    real :: total
    select generic rank (x)
    rank (0)
      total = real(x[this_image()])
    rank (1)
      total = real(sum(x(:)[this_image()]))
    end select
  end function
end module

program integration_reject_volatile_coarray_mismatch_p
  use integration_reject_volatile_coarray_mismatch_m
  implicit none
  integer :: plain[*]
  plain = 1
  sync all
  ! TEST-ERROR-HERE
  if (volatile_peek(plain) /= 1.0) error stop "unreachable"
end program
