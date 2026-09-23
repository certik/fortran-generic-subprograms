! TEST-RULE: R831 R832 R833 R1150 R1152 11.1.10.2
! TEST-PASS: select_rank_gaps
! A rank that matches no guard, and no RANK DEFAULT, selects nothing
! (11.1.10.2). A guard rank outside the dummy's set never matches. That
! block is deleted from every specific, so it may use syntax that is illegal
! for every rank the dummy actually has.
module select_rank_gaps_m
  implicit none
contains
  generic function unmatched(x) result(n)
    integer, intent(in), rank(0:2) :: x
    integer :: n
    n = 0
    select generic rank (x)
    rank (0)
      n = 1
    end select
  end function

  generic function outside(x) result(n)
    integer, intent(in), rank(0:1) :: x
    integer :: n
    n = 0
    select generic rank (x)
    rank (0)
      n = 1
    rank (7)
      n = x(1, 1, 1, 1, 1, 1, 1)
    end select
  end function
end module

program select_rank_gaps_p
  use select_rank_gaps_m
  implicit none
  integer :: r1(2), r2(1, 2), s1(3)
  if (unmatched(0) /= 1) error stop "rank 0 matched"
  if (unmatched(r1) /= 0) error stop "rank 1 unmatched"
  if (unmatched(r2) /= 0) error stop "rank 2 unmatched"
  if (outside(0) /= 1) error stop "outside rank 0"
  if (outside(s1) /= 0) error stop "outside rank 1 uses no default"
  print '(a)', 'TEST-PASS: select_rank_gaps'
end program
