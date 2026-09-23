! TEST-RULE: C885 C1550 8.5.21 15.3.2.2 15.5.2.9 15.6.2.4
! TEST-PASS: audit-integration-coarray-volatile
! VOLATILE is a characteristic of every generated coarray dummy
! (15.3.2.2), so each specific requires a VOLATILE coarray actual
! (15.5.2.9 p1). Whole coarrays, not coindexed objects, are passed (C1550),
! and the dummies are INTENT(INOUT) because C885 excludes VOLATILE INTENT(IN).
! The mismatched actual is integration_reject_volatile_coarray_mismatch.f90.
! The case also runs on one image.
module audit_integration_coarray_volatile_m
  implicit none
  private
  public :: volatile_peek
contains
  generic function volatile_peek(x) result(total)
    type(integer, real), volatile, intent(inout), rank(0:1) :: x[*]
    real :: total
    select generic rank (x)
    rank (0)
      total = real(x[this_image()])
    rank (1)
      total = real(sum(x(:)[this_image()])) + real(size(x))
    end select
  end function
end module

program audit_integration_coarray_volatile_p
  use audit_integration_coarray_volatile_m
  implicit none
  integer, volatile :: vi[*]
  real, volatile :: vr[*]
  integer, volatile :: vis(3)[*]
  real, volatile :: vrs(2)[*]
  vi = 4*this_image()
  vr = 0.5*this_image()
  vis = [1, 2, 3]*this_image()
  vrs = [1.5, 2.5]*this_image()
  sync all
  if (volatile_peek(vi) /= real(4*this_image())) error stop "integer scalar VOLATILE coarray"
  if (volatile_peek(vr) /= 0.5*this_image()) error stop "real scalar VOLATILE coarray"
  if (volatile_peek(vis) /= real(6*this_image() + 3)) error stop "integer vector VOLATILE coarray"
  if (volatile_peek(vrs) /= 4.0*this_image() + 2.0) error stop "real vector VOLATILE coarray"
  sync all
  print '(a)', 'TEST-PASS: audit-integration-coarray-volatile'
end program
