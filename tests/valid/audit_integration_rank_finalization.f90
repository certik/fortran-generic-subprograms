! TEST-RULE: C759 C15104 C15107 C15117 7.5.2.3 7.5.6.2 7.5.6.3 15.6.2.4 15.7 15.9.1
! TEST-PASS: audit-integration-rank-finalization
! Generated specifics finalize INTENT(OUT) dummies and deallocated
! RANK(RANK(x)) locals with the final subroutine for that specific's rank.
! Purity is checked per retained specific: PURE and implicitly pure
! ELEMENTAL families are valid because every finalization they retain is
! pure. An elemental reference with a rank-two actual uses the scalar final
! (7.5.6.3 p7), so the impure rank-two final is not called. Impure
! finalization inside a never-retained SELECT GENERIC block is pruned, and a
! PURE family may return CLASSOF allocatable results of pure types (C15104).
module audit_integration_rank_finalization_m
  implicit none
  private
  public :: tracked, quiet_tracked, calm_tracked
  public :: pure_left, left_child, pure_right, right_child
  public :: reset, churn, quiet_reset, loud_reset, elemental_reset
  public :: checked_weight, pure_clone, counts

  integer :: scalar_finals = 0, vector_finals = 0, matrix_finals = 0
  integer :: last_scalar = 0, last_vector = 0, last_matrix = 0
  integer :: noisy_finals = 0

  type :: tracked
    integer :: tag = 0
  contains
    final :: final_scalar, final_vector, final_matrix
  end type

  type :: quiet_tracked
    integer :: tag = 0
  contains
    final :: quiet_final_scalar, quiet_final_vector, noisy_final_matrix
  end type

  type :: calm_tracked
    integer :: tag = 0
  contains
    final :: calm_final
  end type

  type, pure :: pure_left
    integer :: id = 0
  end type
  type, pure, extends(pure_left) :: left_child
    integer :: extra = 0
  end type
  type, pure :: pure_right
    integer :: weight = 0
  end type
  type, pure, extends(pure_right) :: right_child
    integer :: bonus = 0
  end type
contains
  subroutine final_scalar(x)
    type(tracked), intent(inout) :: x
    scalar_finals = scalar_finals + 1
    last_scalar = x%tag
  end subroutine

  subroutine final_vector(x)
    type(tracked), intent(inout) :: x(:)
    vector_finals = vector_finals + 1
    last_vector = sum(x%tag)
  end subroutine

  subroutine final_matrix(x)
    type(tracked), intent(inout) :: x(:, :)
    matrix_finals = matrix_finals + 1
    last_matrix = sum(x%tag)
  end subroutine

  pure subroutine quiet_final_scalar(x)
    type(quiet_tracked), intent(inout) :: x
    x%tag = -x%tag
  end subroutine

  pure subroutine quiet_final_vector(x)
    type(quiet_tracked), intent(inout) :: x(:)
    x%tag = -x%tag
  end subroutine

  subroutine noisy_final_matrix(x)
    type(quiet_tracked), intent(inout) :: x(:, :)
    noisy_finals = noisy_finals + 1
  end subroutine

  elemental subroutine calm_final(x)
    type(calm_tracked), intent(inout) :: x
    x%tag = 0
  end subroutine

  subroutine counts(scalar, vector, matrix, noisy, scalar_tag, vector_sum, matrix_sum)
    integer, intent(out) :: scalar, vector, matrix, noisy
    integer, intent(out) :: scalar_tag, vector_sum, matrix_sum
    scalar = scalar_finals
    vector = vector_finals
    matrix = matrix_finals
    noisy = noisy_finals
    scalar_tag = last_scalar
    vector_sum = last_vector
    matrix_sum = last_matrix
  end subroutine

  generic subroutine reset(x, tag)
    type(tracked), intent(out), rank(0:2) :: x
    integer, intent(in) :: tag
    x%tag = tag
  end subroutine

  generic subroutine churn(x)
    type(tracked), intent(in), rank(0:2) :: x
    typeof(x), allocatable, rank(rank(x)) :: work, spare
    allocate(work, source=x)
    work%tag = work%tag + 100
    deallocate(work)
    allocate(spare, source=x)
  end subroutine

  pure generic subroutine quiet_reset(x, tag)
    type(quiet_tracked), intent(out), rank(0:1) :: x
    integer, intent(in) :: tag
    x%tag = tag
  end subroutine

  generic subroutine loud_reset(x, tag)
    type(quiet_tracked), intent(out), rank(1:2) :: x
    integer, intent(in) :: tag
    x%tag = tag
  end subroutine

  elemental generic subroutine elemental_reset(x, tag)
    type(quiet_tracked, calm_tracked), intent(out) :: x
    integer, intent(in) :: tag
    x%tag = tag
  end subroutine

  elemental generic function checked_weight(x) result(w)
    type(quiet_tracked, calm_tracked), intent(in) :: x
    integer :: w
    select generic type (x)
    declared type is (tracked)
      block
        type(tracked) :: scratch
        scratch%tag = 1
        w = scratch%tag
      end block
    declared type is (quiet_tracked)
      w = 10*x%tag
    declared type is (calm_tracked)
      w = 20*x%tag
    end select
  end function

  pure generic function pure_clone(x) result(y)
    class(pure_left, pure_right), intent(in), rank(0:1) :: x
    classof(x), allocatable, rank(rank(x)) :: y
    allocate(y, source=x)
  end function
end module

program audit_integration_rank_finalization_p
  use audit_integration_rank_finalization_m
  implicit none
  type(tracked) :: one, row(3), grid(2, 2)
  type(quiet_tracked) :: q_one, q_row(2), q_grid(2, 2)
  type(calm_tracked) :: c_one, c_row(3)
  type(left_child) :: lc
  type(pure_left) :: pl(2)
  type(pure_right) :: pr
  type(right_child) :: rcs(2)
  class(pure_left), allocatable :: left_one, left_many(:)
  class(pure_right), allocatable :: right_one, right_many(:)
  integer :: s, v, m, noisy, ls, lv, lm

  one%tag = 1
  row%tag = [1, 2, 3]
  grid%tag = reshape([1, 2, 3, 4], [2, 2])
  call reset(one, 5)
  call counts(s, v, m, noisy, ls, lv, lm)
  if (s /= 1 .or. v /= 0 .or. m /= 0 .or. ls /= 1) error stop "scalar INTENT(OUT) final"
  if (one%tag /= 5) error stop "scalar reset value"
  call reset(row, 7)
  call counts(s, v, m, noisy, ls, lv, lm)
  if (s /= 1 .or. v /= 1 .or. m /= 0 .or. lv /= 6) error stop "vector INTENT(OUT) final"
  if (any(row%tag /= 7)) error stop "vector reset value"
  call reset(grid, 9)
  call counts(s, v, m, noisy, ls, lv, lm)
  if (s /= 1 .or. v /= 1 .or. m /= 1 .or. lm /= 10) error stop "matrix INTENT(OUT) final"
  if (any(grid%tag /= 9)) error stop "matrix reset value"

  call churn(one)
  call counts(s, v, m, noisy, ls, lv, lm)
  if (s /= 3 .or. v /= 1 .or. m /= 1) error stop "scalar local finalization count"
  if (ls /= 5) error stop "scalar automatic deallocation final"
  call churn(row)
  call counts(s, v, m, noisy, ls, lv, lm)
  if (s /= 3 .or. v /= 3 .or. m /= 1) error stop "vector local finalization count"
  if (lv /= 21) error stop "vector automatic deallocation final"
  call churn(grid)
  call counts(s, v, m, noisy, ls, lv, lm)
  if (s /= 3 .or. v /= 3 .or. m /= 3) error stop "matrix local finalization count"
  if (lm /= 36) error stop "matrix automatic deallocation final"
  if (one%tag /= 5 .or. any(row%tag /= 7) .or. any(grid%tag /= 9)) then
    error stop "INTENT(IN) actuals changed"
  end if

  q_one%tag = 3
  q_row%tag = [4, 5]
  q_grid%tag = reshape([6, 7, 8, 9], [2, 2])
  call quiet_reset(q_one, 11)
  call quiet_reset(q_row, 12)
  if (q_one%tag /= 11 .or. any(q_row%tag /= 12)) error stop "pure rank-generic reset"
  call loud_reset(q_row, 13)
  call counts(s, v, m, noisy, ls, lv, lm)
  if (noisy /= 0 .or. any(q_row%tag /= 13)) error stop "rank-one final stays pure"
  call loud_reset(q_grid, 14)
  call counts(s, v, m, noisy, ls, lv, lm)
  if (noisy /= 1 .or. any(q_grid%tag /= 14)) error stop "rank-two final retained"
  call elemental_reset(q_grid, 15)
  call counts(s, v, m, noisy, ls, lv, lm)
  if (noisy /= 1) error stop "elemental INTENT(OUT) used a rank-two final"
  if (any(q_grid%tag /= 15)) error stop "elemental quiet reset value"
  call elemental_reset(q_one, 16)
  if (q_one%tag /= 16) error stop "scalar elemental quiet reset"
  c_one%tag = 1
  c_row%tag = [2, 3, 4]
  call elemental_reset(c_one, 17)
  call elemental_reset(c_row, 18)
  if (c_one%tag /= 17 .or. any(c_row%tag /= 18)) error stop "elemental calm reset"
  if (checked_weight(q_one) /= 160) error stop "pruned impure block, quiet scalar"
  if (any(checked_weight(q_grid) /= 150)) error stop "pruned impure block, quiet array"
  if (any(checked_weight(c_row) /= 360)) error stop "pruned impure block, calm array"
  call counts(s, v, m, noisy, ls, lv, lm)
  if (s /= 3 .or. v /= 3 .or. m /= 3 .or. noisy /= 1) error stop "no unexpected final"

  lc = left_child(id=3, extra=30)
  pl = [pure_left(1), pure_left(2)]
  pr = pure_right(weight=4)
  rcs = [right_child(weight=5, bonus=50), right_child(weight=6, bonus=60)]
  allocate(left_one, source=pure_clone(lc))
  select type (left_one)
  type is (left_child)
    if (left_one%id /= 3 .or. left_one%extra /= 30) error stop "pure scalar left clone"
  class default
    error stop "pure scalar left dynamic type"
  end select
  allocate(left_many, source=pure_clone(pl))
  select type (left_many)
  type is (pure_left)
    if (size(left_many) /= 2 .or. any(left_many%id /= [1, 2])) then
      error stop "pure vector left clone"
    end if
  class default
    error stop "pure vector left dynamic type"
  end select
  allocate(right_one, source=pure_clone(pr))
  select type (right_one)
  type is (pure_right)
    if (right_one%weight /= 4) error stop "pure scalar right clone"
  class default
    error stop "pure scalar right dynamic type"
  end select
  allocate(right_many, source=pure_clone(rcs))
  select type (right_many)
  type is (right_child)
    if (size(right_many) /= 2 .or. any(right_many%bonus /= [50, 60])) then
      error stop "pure vector right clone"
    end if
  class default
    error stop "pure vector right dynamic type"
  end select
  print '(a)', 'TEST-PASS: audit-integration-rank-finalization'
end program
