! TEST-RULE: C725 C845 R828 7.3.2.3 8.5.8.7
! TEST-PASS: language_array_domains_expanded
! Ordinary/manual specialization control for language_array_domains.f90.
! The six concrete type/rank procedures map the type-generic assumed-rank
! family, and the two TYPE(*) procedures use only the permitted RANK inquiry.
module language_array_domains_expanded_m
  implicit none
  type :: blob
    integer :: value
  end type

  interface assumed_rank_sum_control
    module procedure integer_scalar_sum
    module procedure integer_vector_sum
    module procedure integer_matrix_sum
    module procedure real_scalar_sum
    module procedure real_vector_sum
    module procedure real_matrix_sum
  end interface

  interface assumed_type_rank_control
    module procedure assumed_type_scalar_rank
    module procedure assumed_type_vector_rank
  end interface
contains
  function integer_scalar_sum(x) result(s)
    integer, intent(in) :: x
    real :: s
    s = real(x, kind=kind(s))
  end function

  function integer_vector_sum(x) result(s)
    integer, intent(in) :: x(:)
    real :: s
    s = real(sum(x), kind=kind(s))
  end function

  function integer_matrix_sum(x) result(s)
    integer, intent(in) :: x(:, :)
    real :: s
    s = real(sum(x), kind=kind(s))
  end function

  function real_scalar_sum(x) result(s)
    real, intent(in) :: x
    real :: s
    s = real(x, kind=kind(s))
  end function

  function real_vector_sum(x) result(s)
    real, intent(in) :: x(:)
    real :: s
    s = real(sum(x), kind=kind(s))
  end function

  function real_matrix_sum(x) result(s)
    real, intent(in) :: x(:, :)
    real :: s
    s = real(sum(x), kind=kind(s))
  end function

  function assumed_type_scalar_rank(x) result(n)
    type(*), intent(in) :: x
    integer :: n
    n = rank(x)
  end function

  function assumed_type_vector_rank(x) result(n)
    type(*), intent(in) :: x(:)
    integer :: n
    n = rank(x)
  end function
end module

program language_array_domains_expanded_p
  use language_array_domains_expanded_m
  implicit none
  integer :: i(2), im(2, 2)
  real :: r(2), rm(2, 2)
  type(blob) :: b, ba(2)

  i = [2, 3]
  im = reshape([1, 2, 3, 4], [2, 2])
  r = [1.5, 2.5]
  rm = reshape([0.5, 1.5, 2.5, 3.5], [2, 2])
  b%value = 1
  ba(1)%value = 2
  ba(2)%value = 3
  if (assumed_rank_sum_control(4) /= 4.0) error stop "integer scalar control"
  if (assumed_rank_sum_control(i) /= 5.0) error stop "integer vector control"
  if (assumed_rank_sum_control(im) /= 10.0) error stop "integer matrix control"
  if (assumed_rank_sum_control(1.5) /= 1.5) error stop "real scalar control"
  if (assumed_rank_sum_control(r) /= 4.0) error stop "real vector control"
  if (assumed_rank_sum_control(rm) /= 8.0) error stop "real matrix control"
  if (assumed_type_rank_control(b) /= 0) error stop "type star scalar control"
  if (assumed_type_rank_control(ba) /= 1) error stop "type star vector control"
  if (assumed_type_rank_control(i) /= 1) error stop "type star intrinsic control"
  print '(a)', 'TEST-PASS: language_array_domains_expanded'
end program
