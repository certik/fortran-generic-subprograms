! TEST-PASS: audit-language-dependent-kind-domains
! TEST-RULE: R708 C718 10.1.12p2 15.6.2.4
! TEST-REQUIRES: integer_kinds>=2
! Y's intrinsic-kind domain is evaluated for each X kind.  When X has KLO,
! [KIND(X),KLO] deduplicates to one value; for KHI it has two values.
module audit_language_dependent_kind_domains_m
  use, intrinsic :: iso_fortran_env, only: integer_kinds
  implicit none
  private
  public :: kind_pairs
  integer, parameter :: klo = integer_kinds(1)
  integer, parameter :: khi = integer_kinds(size(integer_kinds))
contains
  generic subroutine kind_pairs(x, y, xcode, ycode, total)
    integer([klo, khi]), intent(in) :: x
    integer([kind(x), klo]), intent(in) :: y
    integer, intent(out) :: xcode, ycode, total

    select generic type (x)
    declared type is (integer(klo))
      xcode = 1
      select generic type (y)
      declared type is (integer(klo))
        ycode = 1
      end select
    declared type is (integer(khi))
      xcode = 2
      select generic type (y)
      declared type is (integer(klo))
        ycode = 1
      declared type is (integer(khi))
        ycode = 2
      end select
    end select
    total = int(x) + int(y)
  end subroutine
end module

program audit_language_dependent_kind_domains_p
  use, intrinsic :: iso_fortran_env, only: integer_kinds
  use audit_language_dependent_kind_domains_m, only: kind_pairs
  implicit none
  integer, parameter :: klo = integer_kinds(1)
  integer, parameter :: khi = integer_kinds(size(integer_kinds))
  integer(klo) :: lo0, lo1
  integer(khi) :: hi1
  integer :: xcode, ycode, total

  lo0 = int(0, kind=klo)
  lo1 = int(1, kind=klo)
  hi1 = int(1, kind=khi)
  call kind_pairs(lo0, lo1, xcode, ycode, total)
  call check(xcode, ycode, total, 1, 1, 1)
  call kind_pairs(hi1, lo0, xcode, ycode, total)
  call check(xcode, ycode, total, 2, 1, 1)
  call kind_pairs(hi1, hi1, xcode, ycode, total)
  call check(xcode, ycode, total, 2, 2, 2)

  print '(a)', 'TEST-PASS: audit-language-dependent-kind-domains'
contains
  subroutine check(ax, ay, actual, ex, ey, expected)
    integer, intent(in) :: ax, ay, actual, ex, ey, expected
    if (ax /= ex .or. ay /= ey) error stop "dependent kind domain codes"
    if (actual /= expected) error stop "dependent kind domain payload"
  end subroutine
end program
