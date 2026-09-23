! TEST-RULE: C1160
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1160|(length|len) type parameters?.*assumed|deferred.*guard
! TEST-ERROR-PHASE: compile
! Invalid: C1160. A length parameter in DECLARED TYPE IS is assumed (*),
! not deferred (:).
! Settled under either assumed-length-guards reading: whether or not a
! guard may spell an assumed length with *, a deferred length does not
! specify that the length parameter is assumed.
module pdt_guard_colon_m
  implicit none
  type :: u(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine s(x)
      type(u(k=[kind(0)], n=:)), allocatable :: x
    select generic type (x)
      ! TEST-ERROR-HERE
      declared type is (u(k=kind(0), n=:))
        allocate(u(kind(0), 1) :: x)
      end select
    end subroutine
  end module
