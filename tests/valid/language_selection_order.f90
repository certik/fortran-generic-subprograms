! TEST-RULE: R1150 R1152 R1155 R1157 11.1.10.2 11.1.11.2 15.6.2.4
! TEST-PASS: language_selection_order
! Defaults may be first, middle, or the only guard. SELECT GENERIC constructs
! and individual guarded blocks may be empty. Out-of-set guards are deleted;
! no runtime IF is used to hide operations invalid for retained specifics.
module language_selection_order_m
  implicit none
contains
  generic function type_default_first(x) result(n)
    type(integer, real, logical), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type default
      n = -1
    declared type is (integer)
      n = 10 + x
    declared type is (real)
      n = 20 + nint(x)
    end select
  end function

  generic function type_default_middle(x) result(n)
    type(integer, real, logical), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (integer)
      n = 30 + x
    declared type default
      n = -2
    declared type is (logical)
      n = merge(41, 40, x)
    end select
  end function

  generic subroutine type_default_only(x, code, k)
    type(integer, real), intent(in) :: x
    integer, intent(out) :: code, k
    code = -1
    k = -1
    select generic type (x)
    declared type default
      code = 50
      k = kind(x)
    end select
  end subroutine

  generic subroutine empty_type_construct(x, code, k)
    type(integer, real), intent(in) :: x
    integer, intent(out) :: code, k
    code = 61
    k = kind(x)
    select generic type (x)
    end select
  end subroutine

  generic function empty_type_block(x) result(n)
    type(integer, real, logical), intent(in) :: x
    integer :: n
    n = 0
    select generic type (x)
    declared type is (integer)
    declared type is (real)
      n = 2
    declared type is (logical)
      n = 3
    end select
  end function

  generic function out_of_set_type(x) result(n)
    type(integer, real), intent(in) :: x
    integer :: n
    select generic type (x)
    declared type is (logical)
      n = merge(90, 80, x)
    declared type is (integer)
      n = x
    declared type is (real)
      n = nint(x)
    end select
  end function

  generic function rank_default_first(x) result(n)
    integer, rank(0:2), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank default
      n = -1
    rank (1:2)
      n = 10*rank(x) + sum(x)
    end select
  end function

  generic function rank_default_only(x) result(n)
    integer, rank(0:2), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank default
      n = 70 + rank(x)
    end select
  end function

  generic function rank_default_middle(x) result(n)
    integer, rank(0:2), intent(in) :: x
    integer :: n
    select generic rank (x)
    rank (0)
      n = x
    rank default
      n = -3
    rank (2)
      n = sum(x)
    end select
  end function

  generic function empty_rank_cases(x) result(n)
    integer, rank(0:1), intent(in) :: x
    integer :: n
    n = 0
    select generic rank (x)
    rank (0)
    rank (1)
      n = sum(x)
    end select
  end function

  generic function empty_rank_construct(x) result(n)
    integer, rank(0:1), intent(in) :: x
    integer :: n
    n = 80 + rank(x)
    select generic rank (x)
    end select
  end function
end module

program language_selection_order_p
  use language_selection_order_m
  implicit none
  integer :: v(2), m(1, 2), code, k

  v = [2, 3]
  m = reshape([4, 5], [1, 2])
  if (type_default_first(5) /= 15) error stop "type default first integer"
  if (type_default_first(2.0) /= 22) error stop "type default first real"
  if (type_default_first(.true.) /= -1) error stop "type default first fallback"
  if (type_default_middle(5) /= 35) error stop "type default middle integer"
  if (type_default_middle(2.0) /= -2) error stop "type default middle fallback"
  if (type_default_middle(.true.) /= 41) error stop "type default middle logical"
  ! Kind values are opaque processor values, so they are compared separately
  ! from the selection codes rather than added to them.
  call type_default_only(1, code, k)
  if (code /= 50) error stop "type default only integer selection"
  if (k /= kind(1)) error stop "type default only integer kind"
  call type_default_only(1.0, code, k)
  if (code /= 50) error stop "type default only real selection"
  if (k /= kind(1.0)) error stop "type default only real kind"
  call empty_type_construct(1, code, k)
  if (code /= 61) error stop "empty type integer"
  if (k /= kind(1)) error stop "empty type integer kind"
  call empty_type_construct(1.0, code, k)
  if (code /= 61) error stop "empty type real"
  if (k /= kind(1.0)) error stop "empty type real kind"
  if (empty_type_block(1) /= 0) error stop "empty selected block"
  if (empty_type_block(1.0) /= 2) error stop "nonempty real block"
  if (empty_type_block(.true.) /= 3) error stop "nonempty logical block"
  if (out_of_set_type(7) /= 7) error stop "out-of-set integer"
  if (out_of_set_type(3.0) /= 3) error stop "out-of-set real"
  if (rank_default_first(9) /= -1) error stop "rank default first scalar"
  if (rank_default_first(v) /= 15) error stop "rank range after default"
  if (rank_default_first(m) /= 29) error stop "rank2 range after default"
  if (rank_default_only(1) /= 70) error stop "rank default only scalar"
  if (rank_default_only(v) /= 71) error stop "rank default only vector"
  if (rank_default_only(m) /= 72) error stop "rank default only matrix"
  if (rank_default_middle(8) /= 8) error stop "rank default middle scalar"
  if (rank_default_middle(v) /= -3) error stop "rank default middle fallback"
  if (rank_default_middle(m) /= 9) error stop "rank default middle matrix"
  if (empty_rank_cases(4) /= 0) error stop "empty rank block"
  if (empty_rank_cases(v) /= 5) error stop "nonempty rank block"
  if (empty_rank_construct(4) /= 80) error stop "empty rank construct scalar"
  if (empty_rank_construct(v) /= 81) error stop "empty rank construct vector"
  print '(a)', 'TEST-PASS: language_selection_order'
end program
