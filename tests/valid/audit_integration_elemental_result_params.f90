! TEST-RULE: C15136 C15138 10.1.11 15.6.2.4 15.9.1 15.9.2
! TEST-PASS: audit-integration-elemental-result-params
! Elemental generated specifics may size character and PDT results through
! specification inquiries of their dummies (LEN, KIND, and type parameter
! inquiries); the forbidden value-dependent forms are the paired negatives
! integration_reject_elemental_*_result_length. Scalar and elemental array
! references are made for every generated specific.
module audit_integration_elemental_result_params_m
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  implicit none
  private
  public :: tagged, decorate, relabel

  type :: tagged(k, n)
    integer, kind :: k
    integer, len :: n
    real(k) :: weight
    character(len=n) :: label
  end type
contains
  elemental generic function decorate(label, marker) result(y)
    character(len=*), intent(in) :: label
    type(integer, real), intent(in) :: marker
    character(len=len(label) + 2, kind=kind(label)) :: y
    select generic type (marker)
    declared type is (integer)
      y = 'i' // label // 'i'
      if (marker < 0) y(1:1) = 'n'
    declared type is (real)
      y = 'r' // label // 'r'
      if (marker < 0) y(1:1) = 'n'
    end select
  end function

  elemental generic function relabel(x) result(y)
    type(tagged(k=[single_precision, double_precision], n=*)), intent(in) :: x
    type(tagged(k=x%k, n=x%n + 1)) :: y
    y%weight = 2*x%weight
    y%label = x%label // '+'
  end function
end module

program audit_integration_elemental_result_params_p
  use, intrinsic :: iso_fortran_env, only: single_precision, double_precision
  use audit_integration_elemental_result_params_m
  implicit none
  character(len=:), allocatable :: text, texts(:)
  type(tagged(single_precision, 2)) :: s_item, s_items(3)
  type(tagged(double_precision, 3)) :: d_item, d_items(2)
  type(tagged(single_precision, :)), allocatable :: s_out, s_outs(:)
  type(tagged(double_precision, :)), allocatable :: d_out, d_outs(:)

  text = decorate('ab', 7)
  if (len(text) /= 4 .or. text /= 'iabi') error stop "integer scalar text result"
  text = decorate('xyz', -2.5)
  if (len(text) /= 5 .or. text /= 'nxyzr') error stop "real scalar text result"
  texts = decorate(['pq', 'rs'], [1, -1])
  if (len(texts) /= 4 .or. size(texts) /= 2) error stop "integer elemental text shape"
  if (texts(1) /= 'ipqi' .or. texts(2) /= 'nrsi') error stop "integer elemental text values"
  texts = decorate('m', [0.5, 1.5, -0.5])
  if (len(texts) /= 3 .or. size(texts) /= 3) error stop "real elemental text shape"
  if (texts(1) /= 'rmr' .or. texts(2) /= 'rmr' .or. texts(3) /= 'nmr') then
    error stop "real elemental text values"
  end if

  s_item%weight = 1.5_single_precision
  s_item%label = 'ab'
  s_out = relabel(s_item)
  if (s_out%n /= 3 .or. len(s_out%label) /= 3) error stop "single scalar PDT result length"
  if (s_out%weight /= 3.0_single_precision .or. s_out%label /= 'ab+') then
    error stop "single scalar PDT result values"
  end if
  s_items%weight = [1.0_single_precision, 2.0_single_precision, 3.0_single_precision]
  s_items%label = ['aa', 'bb', 'cc']
  s_outs = relabel(s_items)
  if (size(s_outs) /= 3 .or. s_outs%n /= 3) error stop "single elemental PDT result shape"
  if (any(s_outs%weight /= [2.0_single_precision, 4.0_single_precision, &
      6.0_single_precision])) error stop "single elemental PDT weights"
  if (s_outs(1)%label /= 'aa+' .or. s_outs(3)%label /= 'cc+') then
    error stop "single elemental PDT labels"
  end if

  d_item%weight = 0.25_double_precision
  d_item%label = 'xyz'
  d_out = relabel(d_item)
  if (d_out%n /= 4 .or. len(d_out%label) /= 4) error stop "double scalar PDT result length"
  if (d_out%weight /= 0.5_double_precision .or. d_out%label /= 'xyz+') then
    error stop "double scalar PDT result values"
  end if
  d_items%weight = [5.0_double_precision, 6.0_double_precision]
  d_items%label = ['uvw', 'rst']
  d_outs = relabel(d_items)
  if (size(d_outs) /= 2 .or. d_outs%n /= 4) error stop "double elemental PDT result shape"
  if (any(d_outs%weight /= [10.0_double_precision, 12.0_double_precision])) then
    error stop "double elemental PDT weights"
  end if
  if (d_outs(2)%label /= 'rst+') error stop "double elemental PDT labels"
  print '(a)', 'TEST-PASS: audit-integration-elemental-result-params'
end program
