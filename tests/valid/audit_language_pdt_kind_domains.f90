! TEST-PASS: audit-language-pdt-kind-domains
! TEST-RULE: R708 R712 R713 R714 C718 C719 C721 C722 C723 10.1.12 15.6.2.4
! TEST-REQUIRES: integer_kinds>=2
! A defaulted PDT kind is omitted while another kind uses a rank-one array
! whose own integer kind is nondefault.  Two length parameters exercise
! assumed, deferred, and mixed modes.  PACK and an implied-DO form domains.
module audit_language_pdt_kind_domains_m
  use, intrinsic :: iso_fortran_env, only: integer_kinds
  implicit none
  private
  public :: record, inspect_assumed, inspect_deferred, inspect_mixed
  public :: packed_identity, implied_identity
  public :: domain_integer_kind

  integer, parameter :: klo = integer_kinds(1)
  integer, parameter :: khi = integer_kinds(size(integer_kinds))
  integer, parameter :: domain_integer_kind = &
    merge(integer_kinds(1), integer_kinds(size(integer_kinds)), integer_kinds(1) /= kind(0))
  integer(domain_integer_kind), parameter :: user_domain(2) = &
    [int(0, domain_integer_kind), int(1, domain_integer_kind)]
  integer :: implied_index
  integer, parameter :: endpoints(2) = [klo, khi]
  integer, parameter :: packed_domain(2) = &
    pack([klo, klo, khi, khi], [.true., .false., .true., .false.])
  integer, parameter :: implied_domain(2) = &
    [(endpoints(implied_index), implied_index=1, 2)]

  type :: record(default_k, variant_k, n, m)
    integer, kind :: default_k = 1
    integer, kind :: variant_k
    integer, len :: n, m
    integer :: values(n, m)
  end type
contains
  generic subroutine inspect_assumed(x, code, total)
    type(record(variant_k=user_domain, n=*, m=*)), intent(in) :: x
    integer, intent(out) :: code, total

    select case (x%variant_k)
    case (0)
      code = 100
    case (1)
      code = 200
    case default
      error stop "unexpected assumed PDT kind"
    end select
    total = sum(x%values)
  end subroutine

  generic subroutine inspect_deferred(x, code, total)
    type(record(variant_k=user_domain, n=:, m=:)), allocatable, intent(in) :: x
    integer, intent(out) :: code, total

    if (.not. allocated(x)) error stop "deferred PDT actual not allocated"
    select case (x%variant_k)
    case (0)
      code = 300
    case (1)
      code = 400
    case default
      error stop "unexpected deferred PDT kind"
    end select
    total = sum(x%values)
  end subroutine

  generic subroutine inspect_mixed(x, code, total)
    type(record(variant_k=user_domain, n=*, m=:)), allocatable, intent(in) :: x
    integer, intent(out) :: code, total

    if (.not. allocated(x)) error stop "mixed-mode PDT actual not allocated"
    select case (x%variant_k)
    case (0)
      code = 500
    case (1)
      code = 600
    case default
      error stop "unexpected mixed PDT kind"
    end select
    total = sum(x%values)
  end subroutine

  generic function packed_identity(x) result(y)
    integer(packed_domain), intent(in) :: x
    typeof(x) :: y
    y = x
  end function

  generic function implied_identity(x) result(y)
    integer(implied_domain), intent(in) :: x
    typeof(x) :: y
    y = +x
  end function
end module

program audit_language_pdt_kind_domains_p
  use, intrinsic :: iso_fortran_env, only: integer_kinds
  use audit_language_pdt_kind_domains_m
  implicit none
  integer, parameter :: klo = integer_kinds(1)
  integer, parameter :: khi = integer_kinds(size(integer_kinds))
  type(record(variant_k=0, n=2, m=3)) :: assumed_zero
  type(record(variant_k=1, n=1, m=2)) :: assumed_one
  type(record(variant_k=0, n=:, m=:)), allocatable :: deferred_zero
  type(record(variant_k=1, n=:, m=:)), allocatable :: deferred_one
  type(record(variant_k=0, n=2, m=:)), allocatable :: mixed_zero
  type(record(variant_k=1, n=1, m=:)), allocatable :: mixed_one
  integer(klo) :: lo
  integer(khi) :: hi
  integer :: code, total

  if (domain_integer_kind == kind(0)) error stop "kind-domain array must be nondefault integer"
  assumed_zero%values = reshape([1, 2, 3, 4, 5, 6], [2, 3])
  assumed_one%values = reshape([7, 8], [1, 2])
  call inspect_assumed(assumed_zero, code, total)
  if (code /= 100 .or. total /= 21) error stop "assumed PDT zero"
  if (assumed_zero%default_k /= 1 .or. assumed_zero%variant_k /= 0) then
    error stop "omitted defaulted PDT kind"
  end if
  call inspect_assumed(assumed_one, code, total)
  if (code /= 200 .or. total /= 15) error stop "assumed PDT one"
  if (assumed_one%default_k /= 1 .or. assumed_one%variant_k /= 1) then
    error stop "nondefault integer-kind domain"
  end if

  allocate(record(variant_k=0, n=2, m=1) :: deferred_zero)
  allocate(record(variant_k=1, n=1, m=3) :: deferred_one)
  deferred_zero%values = reshape([9, 10], [2, 1])
  deferred_one%values = reshape([11, 12, 13], [1, 3])
  call inspect_deferred(deferred_zero, code, total)
  if (code /= 300 .or. total /= 19) error stop "deferred PDT zero"
  if (deferred_zero%n /= 2 .or. deferred_zero%m /= 1) error stop "deferred zero lengths"
  call inspect_deferred(deferred_one, code, total)
  if (code /= 400 .or. total /= 36) error stop "deferred PDT one"
  if (deferred_one%n /= 1 .or. deferred_one%m /= 3) then
    error stop "deferred one lengths"
  end if
  allocate(record(variant_k=0, n=2, m=2) :: mixed_zero)
  allocate(record(variant_k=1, n=1, m=3) :: mixed_one)
  mixed_zero%values = reshape([1, 2, 3, 4], [2, 2])
  mixed_one%values = reshape([5, 6, 7], [1, 3])
  call inspect_mixed(mixed_zero, code, total)
  if (code /= 500 .or. total /= 10) error stop "mixed PDT zero"
  call inspect_mixed(mixed_one, code, total)
  if (code /= 600 .or. total /= 18) error stop "mixed PDT one"

  lo = int(0, kind=klo)
  hi = int(1, kind=khi)
  if (packed_identity(lo) /= lo .or. kind(packed_identity(lo)) /= klo) then
    error stop "PACK kind domain low"
  end if
  if (packed_identity(hi) /= hi .or. kind(packed_identity(hi)) /= khi) then
    error stop "PACK kind domain high"
  end if
  if (implied_identity(lo) /= lo .or. kind(implied_identity(lo)) /= klo) then
    error stop "implied-DO kind domain low"
  end if
  if (implied_identity(hi) /= hi .or. kind(implied_identity(hi)) /= khi) then
    error stop "implied-DO kind domain high"
  end if

  print '(a)', 'TEST-PASS: audit-language-pdt-kind-domains'
end program
