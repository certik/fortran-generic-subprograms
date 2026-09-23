! TEST-RULE: C716 C723 C1159
! TEST-DIAGNOSTIC-CLASS: required
! TEST-ERROR: C1159|not.*type-generic|SELECT GENERIC TYPE.*generic dummy
! TEST-ERROR-PHASE: compile
! Invalid: C1159. A parameterized type with only scalar kind parameters is
! an ordinary derived-type spec, not a generic one (C723), and a one-item
! TYPE list without a kind-generic spec is not generic (C716). SELECT
! GENERIC TYPE does not apply. The only guard is DECLARED TYPE DEFAULT, so no
! length-parameter guard question is involved.
module pdt_scalar_not_generic_m
  implicit none
  type :: t(k, n)
    integer, kind :: k
    integer, len :: n
    integer(k) :: v(n)
  end type
contains
  generic subroutine s(x)
      type(t(k=kind(0), n=*)), intent(inout) :: x
      ! TEST-ERROR-HERE
      select generic type (x)
      declared type default
        x%v = 1
    end select
  end subroutine
end module
