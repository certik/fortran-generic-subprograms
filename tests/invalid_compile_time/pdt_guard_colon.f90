! TEST-RULE: C1160
! TEST-DRAFT: assumed-length-guards
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1160|length type parameter.*assumed|deferred.*guard
! TEST-ERROR-PHASE: compile
! Invalid: C1160. A length parameter in DECLARED TYPE IS is assumed (*),
! not deferred (:).
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
