! TEST-PASS: audit-language-select-control
! TEST-RULE: R1150 R1152 R1155 R1157 R1168 C1181 11.1.10.2 15.6.2.4p2
! Named EXIT is exercised on SELECT GENERIC RANK.  Overlapping guards are
! valid when their overlap is wholly outside the selector domain.  The outer
! type selection completely prunes parsable but semantically invalid blocks.
module audit_language_select_control_m
  implicit none

  type :: ghost
    integer :: value
  end type
contains
  generic function rank_exit(x) result(n)
    integer, rank(0:1), intent(in) :: x
    integer :: n

    chosen: select generic rank (x)
    rank (0) chosen
      n = x
      exit chosen
      n = -100
    rank (1) chosen
      n = sum(x)
      exit chosen
      n = -200
    end select chosen
    n = n + 100
  end function

  generic function outside_overlap(x) result(n)
    integer, rank(0:1), intent(in) :: x
    integer :: n

    select generic rank (x)
    rank (2:3)
      n = -20
    rank (3:4)
      n = -30
    rank (0)
      n = x
    rank (1)
      n = sum(x)
    end select
  end function

  pure generic subroutine completely_pruned(x, n)
    type(integer, real), intent(in) :: x
    integer, intent(out) :: n

    select generic type (x)
    declared type is (logical)
      print *, "purity violation only if retained"
    declared type is (complex)
      block
        integer :: invalid_bound(real(x))
        invalid_bound = 0
        n = size(invalid_bound)
      end block
    declared type is (double precision)
      n = missing_name
    declared type is (ghost)
      select generic rank (n)
      rank (0)
        n = -40
      end select
    declared type default
      n = 5
    end select
  end subroutine
end module

program audit_language_select_control_p
  use audit_language_select_control_m
  implicit none
  integer :: vector(3), n

  vector = [2, 3, 4]
  if (rank_exit(7) /= 107) error stop "named rank EXIT scalar"
  if (rank_exit(vector) /= 109) error stop "named rank EXIT vector"
  if (outside_overlap(8) /= 8) error stop "outside overlap scalar"
  if (outside_overlap(vector) /= 9) error stop "outside overlap vector"
  call completely_pruned(1, n)
  if (n /= 5) error stop "pruned integer"
  call completely_pruned(1.0, n)
  if (n /= 5) error stop "pruned real"

  print '(a)', 'TEST-PASS: audit-language-select-control'
end program
