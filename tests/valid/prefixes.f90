! TEST-RULE: C802 C1556 C1557 C1564 C15135 C15137 15.6.2.2 15.9
! TEST-PASS: prefixes
! PURE, SIMPLE, NON_RECURSIVE, IMPURE ELEMENTAL, VALUE, CONTIGUOUS,
! OPTIONAL on a nongeneric dummy, typed results, and no-argument generics.
module prefixes_m
  implicit none
  integer, private :: elemental_calls = 0
contains
  pure generic function add(a, b) result(c)
    type(integer, real), intent(in) :: a
    typeof(a), intent(in) :: b
    typeof(a) :: c
    c = a + b
  end function

  simple generic function sub1(a) result(c)
    type(integer, real), intent(in) :: a
    typeof(a) :: c
    c = a - 1
  end function

  generic function total(x) result(s)
    integer, rank(1:2), value :: x
    integer :: s
    x = x + 1
    s = sum(x)
  end function

  generic function sumc(x) result(s)
    integer, contiguous, rank(1:2), intent(in) :: x
    integer :: s
    if (.not. is_contiguous(x)) error stop "contiguous dummy"
    s = sum(x)
  end function

  generic subroutine bump(x, n)
    type(integer, real), intent(inout) :: x
    integer, optional, intent(in) :: n
    if (present(n)) then
      x = x + n
    else
      x = x + 1
    end if
  end subroutine

  non_recursive generic integer function category(x)
    type(integer, real), intent(in) :: x
    select generic type (x)
    declared type is (integer)
      category = 1
    declared type is (real)
      category = 2
    end select
  end function

  ! RECURSIVE is advisory; recursion is valid without the prefix.
  generic integer function depth(n) result(answer)
    integer, rank(0:0), intent(in) :: n
    if (n == 0) then
      answer = 0
    else
      answer = 1 + depth(n - 1)
    end if
  end function

  impure elemental generic subroutine add_with_side_effect(x)
    integer, rank(0:0), intent(inout) :: x
    x = x + 10
    elemental_calls = elemental_calls + 1
  end subroutine

  elemental generic integer function value_increment(x)
    integer, rank(0:0), value :: x
    x = x + 1
    value_increment = x
  end function

  generic integer function fixed_answer()
    fixed_answer = 123
  end function

  integer function side_effect_count()
    side_effect_count = elemental_calls
  end function
end module

program prefixes_p
  use prefixes_m
  implicit none
  integer :: a(3), a_save(3), b(2, 2), b_save(2, 2), v(6)
  integer :: n, effects(4), effects_before(4)
  real :: r
  a = [1, 2, 3]
  a_save = a
  b = reshape([1, 2, 3, 4], [2, 2])
  b_save = b
  v = [1, 2, 3, 4, 5, 6]
  if (add(2, 3) /= 5) error stop "pure integer"
  if (add(1.5, 2.5) /= 4.0) error stop "pure real"
  if (sub1(4) /= 3) error stop "simple integer"
  if (sub1(2.5) /= 1.5) error stop "simple real"
  if (total(a) /= 9) error stop "value rank1"
  if (any(a /= a_save)) error stop "value leaves actual"
  if (total(b) /= 14) error stop "value rank2"
  if (any(b /= b_save)) error stop "value leaves rank2 actual"
  if (sumc(v(1:6:2)) /= 9) error stop "contiguous section"
  n = 10
  r = 1.5
  call bump(n)
  if (n /= 11) error stop "optional absent"
  call bump(x=r, n=3)
  if (r /= 4.5) error stop "keyword optional"
  call bump(n=2, x=n)
  if (n /= 13) error stop "reordered keywords"
  if (category(4) /= 1) error stop "non-recursive integer"
  if (category(4.0) /= 2) error stop "non-recursive real"
  if (depth(6) /= 6) error stop "implicit recursion"
  effects = [1, 2, 3, 4]
  effects_before = effects
  call add_with_side_effect(effects)
  if (any(effects /= effects_before + 10)) error stop "impure elemental values"
  if (side_effect_count() /= size(effects)) error stop "impure elemental effects"
  if (any(value_increment(effects_before) /= [2, 3, 4, 5])) then
    error stop "elemental value result"
  end if
  if (any(effects_before /= [1, 2, 3, 4])) error stop "elemental value actual"
  if (fixed_answer() /= 123) error stop "no-argument typed generic"
  print '(a)', 'TEST-PASS: prefixes'
end program
