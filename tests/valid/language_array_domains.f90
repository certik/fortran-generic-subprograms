! TEST-RULE: R705 C724 C725 C845 R828 R831 R1150 R1160 8.5.8.7 11.1.12
! Type-generic dummies retain ordinary explicit-shape, assumed-shape,
! assumed-size, and assumed-rank declarations. The assumed-rank dummy uses
! runtime SELECT RANK; its rank does not become a specialization constant.
! CLASS(*) and applicable TYPE(*) dummies are independently rank-generic.
module language_array_domains_m
  implicit none
  type :: blob
    integer :: value
  end type
contains
  generic function explicit_sum(x) result(s)
    type(integer, real), intent(in) :: x(2)
    real :: s
    select generic type (x)
    declared type is (integer)
      s = real(sum(x))
    declared type is (real)
      s = sum(x)
    end select
  end function

  generic function assumed_shape_sum(x) result(s)
    type(integer, real), intent(in) :: x(:)
    real :: s
    select generic type (x)
    declared type is (integer)
      s = real(sum(x))
    declared type is (real)
      s = sum(x)
    end select
  end function

  generic function assumed_size_sum(x, n) result(s)
    type(integer, real), intent(in) :: x(*)
    integer, intent(in) :: n
    real :: s
    select generic type (x)
    declared type is (integer)
      s = real(sum(x(:n)))
    declared type is (real)
      s = sum(x(:n))
    end select
  end function

  generic function assumed_rank_sum(x) result(s)
    type(integer, real), intent(in) :: x(..)
    real :: s
    select rank (x)
    rank (0)
      s = real(x, kind=kind(s))
    rank (1)
      s = real(sum(x), kind=kind(s))
    rank (2)
      s = real(sum(x), kind=kind(s))
    rank default
      error stop "assumed-rank outside control domain"
    end select
  end function

  generic function class_rank_sum(x) result(n)
    class(*), rank(0:1), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank (0)
      select type (x)
      type is (integer)
        n = x
      type is (real)
        n = nint(x)
      class default
        n = -1
      end select
    rank (1)
      select type (x)
      type is (integer)
        n = sum(x)
      type is (real)
        n = nint(sum(x))
      class default
        n = -1
      end select
    end select
  end function

  generic function assumed_type_rank(x) result(n)
    type(*), rank(0:1), intent(in) :: x
    integer :: n
    n = rank(x)
  end function
end module

program language_array_domains_p
  use language_array_domains_m
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
  if (explicit_sum(i) /= 5.0 .or. explicit_sum(r) /= 4.0) error stop "explicit shape"
  if (assumed_shape_sum(i) /= 5.0 .or. assumed_shape_sum(r) /= 4.0) &
    error stop "assumed shape"
  if (assumed_size_sum(i, 2) /= 5.0 .or. assumed_size_sum(r, 2) /= 4.0) &
    error stop "assumed size"
  if (assumed_rank_sum(4) /= 4.0) error stop "assumed rank integer scalar"
  if (assumed_rank_sum(i) /= 5.0) error stop "assumed rank integer vector"
  if (assumed_rank_sum(im) /= 10.0) error stop "assumed rank integer matrix"
  if (assumed_rank_sum(1.5) /= 1.5) error stop "assumed rank real scalar"
  if (assumed_rank_sum(r) /= 4.0) error stop "assumed rank real vector"
  if (assumed_rank_sum(rm) /= 8.0) error stop "assumed rank real matrix"
  if (class_rank_sum(7) /= 7 .or. class_rank_sum(i) /= 5) error stop "class star integer"
  if (class_rank_sum(3.0) /= 3 .or. class_rank_sum(r) /= 4) error stop "class star real"
  if (assumed_type_rank(b) /= 0) error stop "type star derived scalar"
  if (assumed_type_rank(ba) /= 1) error stop "type star derived array"
  if (assumed_type_rank(i) /= 1) error stop "type star intrinsic array"
end program
